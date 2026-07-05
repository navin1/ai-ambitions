import logging
import os
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, UploadFile
from pydantic import BaseModel

import auth

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["admin"])

GCS_PROJECT_ID = os.getenv("GCS_PROJECT_ID") or os.getenv("BIGQUERY_PROJECT_ID", "")
GCS_UPLOAD_BUCKET = os.getenv("GCS_UPLOAD_BUCKET", "")
GCS_UPLOAD_PREFIX = os.getenv("GCS_UPLOAD_PREFIX", "uploads")

MAX_UPLOAD_BYTES = 100 * 1024 * 1024  # 100 MB


class UploadResponse(BaseModel):
    filename: str
    gcs_path: str
    size_bytes: int


@router.post("/upload", response_model=UploadResponse)
async def upload_file(file: UploadFile, user: dict = Depends(auth.require_role("admin"))):
    if not GCS_UPLOAD_BUCKET:
        raise HTTPException(status_code=500, detail="GCS_UPLOAD_BUCKET is not configured")

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="File is empty")
    if len(contents) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail=f"File exceeds the {MAX_UPLOAD_BYTES // (1024 * 1024)}MB limit")

    safe_name = os.path.basename(file.filename or "upload")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    blob_path = f"{GCS_UPLOAD_PREFIX.strip('/')}/{timestamp}_{safe_name}"

    try:
        from google.cloud import storage

        creds = auth.get_gcs_credentials()
        client = storage.Client(project=GCS_PROJECT_ID, credentials=creds)
        blob = client.bucket(GCS_UPLOAD_BUCKET).blob(blob_path)
        blob.upload_from_string(contents, content_type=file.content_type or "application/octet-stream")
    except Exception as exc:
        logger.exception("upload_file: failed to upload %s to gs://%s/%s", safe_name, GCS_UPLOAD_BUCKET, blob_path)
        raise HTTPException(status_code=502, detail=f"GCS upload failed: {exc}")

    logger.info("upload_file: %s uploaded gs://%s/%s (%d bytes)", user["id"], GCS_UPLOAD_BUCKET, blob_path, len(contents))
    return UploadResponse(filename=safe_name, gcs_path=f"gs://{GCS_UPLOAD_BUCKET}/{blob_path}", size_bytes=len(contents))
