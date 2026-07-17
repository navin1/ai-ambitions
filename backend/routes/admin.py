import json
import logging
import os
import time
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, UploadFile

import auth
import bigquery_client
import excel_ingest
from schemas import ImportResponse, RowError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["admin"])

GCS_PROJECT_ID = os.getenv("GCS_PROJECT_ID") or os.getenv("BIGQUERY_PROJECT_ID", "")
GCS_UPLOAD_BUCKET = os.getenv("GCS_UPLOAD_BUCKET", "")
GCS_UPLOAD_PREFIX = os.getenv("GCS_UPLOAD_PREFIX", "ai_ambitions")

MAX_UPLOAD_BYTES = 100 * 1024 * 1024  # 100 MB


def _upload_blob(client, blob_path: str, data: bytes, content_type: str) -> None:
    client.bucket(GCS_UPLOAD_BUCKET).blob(blob_path).upload_from_string(data, content_type=content_type)


def _retry(fn, attempts: int, what: str) -> bool:
    """Runs fn() up to `attempts` times with short backoff. Returns True on
    success, False if every attempt failed (last exception is logged)."""
    for attempt in range(1, attempts + 1):
        try:
            fn()
            return True
        except Exception as exc:
            logger.warning("upload_file: %s attempt %d/%d failed: %s", what, attempt, attempts, exc)
            if attempt < attempts:
                time.sleep(0.5 * attempt)  # 0.5s, 1s, ...
    return False


def _move_blob(client, src_path: str, dst_path: str, attempts: int = 3) -> None:
    """Copies src -> dst then deletes src, retrying transient failures on each
    step before giving up. If the copy still fails after all retries, nothing
    has been archived and the caller should treat this as a real failure. If
    the copy succeeds but the delete still fails after retries, the archive
    record is still durable — the input/ copy just leaks and needs manual
    cleanup, which isn't worth failing the whole request over (the important
    part already succeeded)."""
    bucket = client.bucket(GCS_UPLOAD_BUCKET)
    src_blob = bucket.blob(src_path)

    if not _retry(lambda: bucket.copy_blob(src_blob, bucket, dst_path), attempts, f"copy {src_path} -> {dst_path}"):
        raise RuntimeError(f"failed to copy gs://{GCS_UPLOAD_BUCKET}/{src_path} to gs://{GCS_UPLOAD_BUCKET}/{dst_path} after {attempts} attempts")

    if not _retry(src_blob.delete, attempts, f"delete input copy {src_path}"):
        logger.warning(
            "upload_file: archived to gs://%s/%s but failed to delete input copy gs://%s/%s after %d attempts — needs manual cleanup",
            GCS_UPLOAD_BUCKET, dst_path, GCS_UPLOAD_BUCKET, src_path, attempts,
        )


@router.post("/upload", response_model=ImportResponse)
async def upload_file(file: UploadFile, user: dict = Depends(auth.require_role("admin"))):
    if not GCS_UPLOAD_BUCKET:
        raise HTTPException(status_code=500, detail="GCS_UPLOAD_BUCKET is not configured")

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="File is empty")
    if len(contents) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail=f"File exceeds the {MAX_UPLOAD_BYTES // (1024 * 1024)}MB limit")

    safe_name = os.path.basename(file.filename or "upload")

    # Filenames are validated before anything ever touches GCS — a malformed
    # name is rejected outright, no input/ landing, no archive record.
    expected_period, name_error = excel_ingest.parse_filename(safe_name)
    if name_error:
        name_errors = [RowError(sheet="filename", message=name_error)]
        bigquery_client.log_upload_audit(
            uploaded_by=user["id"], filename=safe_name, fiscal_year=None, period=None,
            outcome="failure", kpi_rows_loaded=0, use_case_rows_loaded=0,
            errors=name_errors, warning=None, gcs_path="",
            creds=auth.get_bq_credentials(),
        )
        return ImportResponse(
            filename=safe_name,
            gcs_path="",
            success=False,
            errors=name_errors,
        )

    base_prefix = GCS_UPLOAD_PREFIX.strip("/")
    input_path = f"{base_prefix}/input/{safe_name}"
    content_type = file.content_type or "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    from google.cloud import storage

    gcs_creds = auth.get_gcs_credentials()
    storage_client = storage.Client(project=GCS_PROJECT_ID, credentials=gcs_creds)

    try:
        _upload_blob(storage_client, input_path, contents, content_type)
    except Exception as exc:
        logger.exception("upload_file: failed to land %s at gs://%s/%s", safe_name, GCS_UPLOAD_BUCKET, input_path)
        raise HTTPException(status_code=502, detail=f"GCS upload failed: {exc}")

    result = excel_ingest.parse_and_validate(contents, expected_period=expected_period)

    kpi_count = 0
    use_case_count = 0
    if result.ok:
        try:
            bq_creds = auth.get_bq_credentials()
            kpi_count, use_case_count = bigquery_client.replace_periods(result.kpi_rows, result.use_case_rows, bq_creds)
            bigquery_client.invalidate_overview_cache()
        except Exception as exc:
            logger.exception("upload_file: BigQuery load failed for %s", safe_name)
            result = excel_ingest.IngestResult(
                ok=False,
                errors=[RowError(sheet="bigquery", message=f"BigQuery load failed: {exc}")],
            )

    # Always clear the input/ landing spot — the file ends up only in
    # archive/success or archive/failure, never both places at once. The
    # attempt_id prefix gives every upload attempt its own permanent archive
    # object — without it, re-uploading the same conventionally-named file
    # would silently overwrite the previous attempt's record (no bucket
    # versioning), losing history instead of just replacing a landing copy.
    outcome_dir = "success" if result.ok else "failure"
    attempt_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    final_path = f"{base_prefix}/archive/{outcome_dir}/{attempt_id}_{safe_name}"
    warning = None
    try:
        _move_blob(storage_client, input_path, final_path)
        if not result.ok:
            errors_payload = json.dumps([e.model_dump() for e in result.errors], indent=2)
            _upload_blob(storage_client, f"{final_path}.errors.json", errors_payload.encode("utf-8"), "application/json")
        gcs_path = f"gs://{GCS_UPLOAD_BUCKET}/{final_path}"
    except Exception as exc:
        logger.exception("upload_file: failed to archive %s to gs://%s/%s", safe_name, GCS_UPLOAD_BUCKET, final_path)
        if not result.ok:
            # Nothing succeeded here either way — a hard error is accurate, not misleading.
            raise HTTPException(status_code=502, detail=f"GCS archive failed: {exc}")
        # The data change (BigQuery) already committed — don't report a real
        # success as a failure just because the archive copy step hiccuped
        # afterward. The file is very likely still sitting in input/, unarchived.
        gcs_path = f"gs://{GCS_UPLOAD_BUCKET}/{input_path}"
        warning = (
            f"Data loaded successfully, but archiving to GCS failed: {exc}. "
            f"The uploaded file may still be sitting at {gcs_path} — check manually."
        )
    logger.info(
        "upload_file: %s processed %s -> %s (%s, kpi_rows=%d, use_case_rows=%d)",
        user["id"], safe_name, gcs_path, outcome_dir, kpi_count, use_case_count,
    )

    bigquery_client.log_upload_audit(
        uploaded_by=user["id"], filename=safe_name,
        fiscal_year=expected_period[0], period=expected_period[1],
        outcome="success" if result.ok else "failure",
        kpi_rows_loaded=kpi_count, use_case_rows_loaded=use_case_count,
        errors=result.errors, warning=warning, gcs_path=gcs_path,
        creds=auth.get_bq_credentials(),
    )

    return ImportResponse(
        filename=safe_name,
        gcs_path=gcs_path,
        success=result.ok,
        periods_replaced=result.periods if result.ok else [],
        kpi_rows_loaded=kpi_count,
        use_case_rows_loaded=use_case_count,
        errors=result.errors,
        warning=warning,
    )
