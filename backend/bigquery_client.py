import os
import logging
import time
import uuid
from typing import Optional
from concurrent.futures import ThreadPoolExecutor
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

PROJECT_ID    = os.getenv("BIGQUERY_PROJECT_ID", "")
DATASET       = os.getenv("BIGQUERY_DATASET", "ai_ambitions")
JOB_PROJECT   = (
    os.getenv("BQ_JOB_PROJECT_ID")
    or os.getenv("GOOGLE_CLOUD_PROJECT")
    or os.getenv("GCP_PROJECT_ID")
    or PROJECT_ID
)

VALID_PERIODS = {"YTD", "Q1", "Q2", "Q3", "Q4"}
PERIOD_ORDER = ["YTD", "Q1", "Q2", "Q3", "Q4"]

# is_spend: True for the AI Cost tile; its kpi_summary row is stored in raw
# dollars (see _build_tile_val) and its plan value is a budget cap, not a
# target band, unlike the other (percent/points) tiles.
TILE_META: dict[str, dict] = {
    "revenue":    {"is_spend": False},
    "nps":        {"is_spend": False},
    "efficiency": {"is_spend": False},
    "ai-cost":    {"is_spend": True},
}

KPI_ORDER = ["ai-cost", "revenue", "nps", "efficiency"]

# Simple in-process cache for overview responses to speed repeated loads
# keyed by "{fiscal_year}:{period}" -> (timestamp, response_dict)
_OVERVIEW_CACHE: dict[str, tuple[float, dict]] = {}
_OVERVIEW_CACHE_TTL = 45.0  # short enough that admin uploads feel near-instant, long
                            # enough to absorb the frequent staleTime:0 background
                            # refetches from every tab switch/remount on the frontend


def invalidate_overview_cache() -> None:
    """Call after a successful admin data upload so stale figures aren't served
    for the rest of the TTL window."""
    _OVERVIEW_CACHE.clear()


# ── Credential / client helpers ───────────────────────────────────────────────

def _client(creds=None):
    from google.cloud import bigquery
    return bigquery.Client(project=JOB_PROJECT or PROJECT_ID, credentials=creds)


# ── Generic query runner (used by dormant query/chat routes) ──────────────────

def run_query(sql: str, token: Optional[str] = None) -> list[dict]:
    from auth import get_bq_credentials
    creds = get_bq_credentials(token)
    return _run_raw(sql, creds)


def _run_raw(sql: str, creds) -> list[dict]:
    client = _client(creds)
    rows = list(client.query(sql).result())
    result = []
    for row in rows:
        record: dict = {}
        for key, val in row.items():
            if hasattr(val, "isoformat"):
                val = val.isoformat()
            elif hasattr(val, "item"):  # numpy scalar
                val = val.item()
            record[key] = val
        result.append(record)
    return result


# ── Excel-import replace (admin upload pipeline) ──────────────────────────────
# Column order mirrors bigquery/schema.sql (excluding update_ts, stamped here).

KPI_SUMMARY_TABLE = "ai_amb_kpi_summary"
USE_CASE_TABLE = "ai_amb_use_case_data"

KPI_SCHEMA = [
    ("fiscal_year", "INT64"), ("period", "STRING"), ("kpi_id", "STRING"),
    ("actual_value", "FLOAT64"), ("plan_value", "FLOAT64"), ("actual_delta", "FLOAT64"),
    ("delta_label", "STRING"), ("range_min", "FLOAT64"), ("range_max", "FLOAT64"),
    ("target_min", "FLOAT64"), ("target_max", "FLOAT64"),
]

USE_CASE_SCHEMA = [
    ("fiscal_year", "INT64"), ("period", "STRING"), ("use_case", "STRING"),
    ("description", "STRING"), ("csg", "STRING"), ("functional_area", "STRING"),
    ("cost_actual", "FLOAT64"), ("cost_plan", "FLOAT64"),
    ("revenue_actual", "FLOAT64"), ("revenue_plan", "FLOAT64"),
    ("revenue_actual_dollars", "FLOAT64"), ("revenue_plan_dollars", "FLOAT64"), ("revenue_notes", "STRING"),
    ("nps_actual", "FLOAT64"), ("nps_plan", "FLOAT64"), ("nps_notes", "STRING"),
    ("efficiency_actual", "FLOAT64"), ("efficiency_plan", "FLOAT64"), ("efficiency_notes", "STRING"),
    ("current_phase", "STRING"),
]


def _replace_table(client, rows: list[dict], columns: list[tuple[str, str]], table_name: str) -> int:
    """Loads `rows` into a temp staging table, then atomically deletes any existing
    rows sharing a (fiscal_year, period) with the new data and inserts the new
    rows in their place — scoped replace, not a full-table wipe."""
    from google.cloud import bigquery
    import pandas as pd

    if not rows:
        return 0

    col_names = [name for name, _ in columns]
    df = pd.DataFrame(rows).reindex(columns=col_names)

    target_ref = f"{PROJECT_ID}.{DATASET}.{table_name}"
    stg_ref = f"{PROJECT_ID}.{DATASET}._stg_{table_name}_{uuid.uuid4().hex[:12]}"

    schema = [bigquery.SchemaField(name, bq_type) for name, bq_type in columns]
    job_config = bigquery.LoadJobConfig(schema=schema, write_disposition="WRITE_TRUNCATE")
    client.load_table_from_dataframe(df, stg_ref, job_config=job_config).result()

    try:
        col_list = ", ".join(col_names)
        script = f"""
        BEGIN TRANSACTION;
        DELETE FROM `{target_ref}` t
        WHERE EXISTS (
          SELECT 1 FROM `{stg_ref}` s
          WHERE s.fiscal_year = t.fiscal_year AND s.period = t.period
        );
        INSERT INTO `{target_ref}` ({col_list}, update_ts)
        SELECT {col_list}, CURRENT_TIMESTAMP() FROM `{stg_ref}`;
        COMMIT TRANSACTION;
        """
        client.query(script).result()
    finally:
        client.delete_table(stg_ref, not_found_ok=True)

    return len(rows)


def replace_periods(kpi_rows: list[dict], use_case_rows: list[dict], creds) -> tuple[int, int]:
    """Replaces rows in both tables scoped to the (fiscal_year, period) pairs
    present in the uploaded data; other years/periods are left untouched."""
    client = _client(creds)
    kpi_count = _replace_table(client, kpi_rows, KPI_SCHEMA, KPI_SUMMARY_TABLE)
    use_case_count = _replace_table(client, use_case_rows, USE_CASE_SCHEMA, USE_CASE_TABLE)
    return kpi_count, use_case_count


UPLOAD_AUDIT_TABLE = "ai_amb_upload_audit"


def log_upload_audit(
    *,
    uploaded_by: str,
    filename: str,
    fiscal_year: Optional[int],
    period: Optional[str],
    outcome: str,
    kpi_rows_loaded: int,
    use_case_rows_loaded: int,
    errors: list,
    warning: Optional[str],
    gcs_path: str,
    creds,
) -> None:
    """Best-effort audit log of an admin Excel-upload attempt into
    ai_amb_upload_audit. Never raises — a logging failure must not affect the
    actual upload outcome already returned to the caller."""
    import json
    from datetime import datetime, timezone
    from google.cloud import bigquery

    try:
        client = _client(creds)
        table_ref = f"{PROJECT_ID}.{DATASET}.{UPLOAD_AUDIT_TABLE}"
        errors_json = json.dumps([e.model_dump() for e in errors]) if errors else None
        query = f"""
            INSERT INTO `{table_ref}`
              (upload_ts, uploaded_by, filename, fiscal_year, period, outcome,
               kpi_rows_loaded, use_case_rows_loaded, error_count, errors_json, warning, gcs_path)
            VALUES
              (@upload_ts, @uploaded_by, @filename, @fiscal_year, @period, @outcome,
               @kpi_rows_loaded, @use_case_rows_loaded, @error_count, @errors_json, @warning, @gcs_path)
        """
        job_config = bigquery.QueryJobConfig(query_parameters=[
            bigquery.ScalarQueryParameter("upload_ts", "TIMESTAMP", datetime.now(timezone.utc)),
            bigquery.ScalarQueryParameter("uploaded_by", "STRING", uploaded_by),
            bigquery.ScalarQueryParameter("filename", "STRING", filename),
            bigquery.ScalarQueryParameter("fiscal_year", "INT64", fiscal_year),
            bigquery.ScalarQueryParameter("period", "STRING", period),
            bigquery.ScalarQueryParameter("outcome", "STRING", outcome),
            bigquery.ScalarQueryParameter("kpi_rows_loaded", "INT64", kpi_rows_loaded),
            bigquery.ScalarQueryParameter("use_case_rows_loaded", "INT64", use_case_rows_loaded),
            bigquery.ScalarQueryParameter("error_count", "INT64", len(errors)),
            bigquery.ScalarQueryParameter("errors_json", "STRING", errors_json),
            bigquery.ScalarQueryParameter("warning", "STRING", warning),
            bigquery.ScalarQueryParameter("gcs_path", "STRING", gcs_path),
        ])
        client.query(query, job_config=job_config).result()
    except Exception:
        logger.warning("log_upload_audit: failed to write audit row for %s", filename, exc_info=True)


def build_schema_context(token: Optional[str] = None) -> str:
    """Returns a schema string for the AI use-case tables (used by dormant routes)."""
    from auth import get_bq_credentials
    creds = get_bq_credentials(token)
    try:
        from google.cloud import bigquery
        client = _client(creds)
        dataset_ref = client.dataset(DATASET, project=PROJECT_ID)
        tables = list(client.list_tables(dataset_ref))
        lines = []
        for t in tables:
            tbl = client.get_table(t)
            lines.append(f"Table: `{PROJECT_ID}.{DATASET}.{tbl.table_id}`")
            for field in tbl.schema:
                lines.append(f"  {field.name} {field.field_type}")
        return "\n".join(lines)
    except Exception as exc:
        logger.warning("build_schema_context failed: %s", exc)
        return ""


def fetch_column_sample_values(columns: list[str], token: Optional[str] = None) -> dict[str, list[str]]:
    return {}


# ── Value formatting (backend mirrors frontend display logic) ─────────────────

# val is in millions (e.g. 38.5 == $38.5M) — auto-scale so small amounts
# don't round away to "$0.0M"
def _fmt_dollars_auto(val: float, decimals: int = 1) -> str:
    abs_val = abs(val)
    if abs_val >= 1:
        return f"${val:.{decimals}f}M"
    if abs_val >= 0.001:
        return f"${val * 1_000:.{decimals}f}K"
    return f"${val * 1_000_000:.{decimals}f}"


def _fmt_value(kpi_id: str, val: float) -> str:
    if kpi_id == "revenue":
        return f"{val:.1f}%"
    if kpi_id == "nps":
        return f"{val:.1f}pts"
    if kpi_id == "efficiency":
        return f"{val:.1f}%"
    if kpi_id == "ai-cost":
        return _fmt_dollars_auto(val)
    return str(val)


def _fmt_delta(kpi_id: str, delta: float) -> str:
    if kpi_id == "ai-cost":
        sign = "−" if delta < 0 else "+"   # U+2212 minus sign
        return f"{sign}{_fmt_dollars_auto(abs(delta))}"
    sign = "+" if delta >= 0 else ""
    return f"{sign}{delta:.1f}"


def _fmt_plan_label(kpi_id: str, plan_val: float) -> str | None:
    if kpi_id == "revenue":
        return f"Plan {plan_val:.1f}%"
    if kpi_id == "nps":
        return f"Plan {plan_val:.1f}pts"
    if kpi_id == "efficiency":
        return f"Plan {plan_val:.1f}%"
    return None


def _compute_status(kpi_id: str, actual: float, plan: float, meta: dict, target_min: float | None, target_max: float | None) -> tuple[str, str]:
    if meta["is_spend"]:
        if actual < plan:
            return "under-plan", "UNDER PLAN"
        if actual > plan:
            return "over-plan", "OVER PLAN"
        return "in-band", "IN BAND"
    else:
        t_min = target_min if target_min is not None else 0
        t_max = target_max if target_max is not None else 100
        if actual < t_min:
            return "below-target", "BELOW TARGET"
        if actual > t_max:
            return "above-target", "ABOVE TARGET"
        return "in-band", "IN BAND"


# cost_actual/cost_plan/revenue_actual_dollars/revenue_plan_dollars are stored
# in BigQuery as raw dollars (both the Excel upload path and seed_data.sql load
# them that way), but the frontend renders everything in millions — convert
# once here, at the point they leave BigQuery.
def _dollars_to_millions(v) -> Optional[float]:
    return float(v) / 1_000_000 if v is not None else None


def _build_tile_val(kpi_id: str, row: dict, meta: dict) -> dict:
    actual = float(row.get("actual_value") or 0)
    plan   = float(row.get("plan_value")   or 0)
    delta  = float(row.get("actual_delta") or 0)
    delta_label = row.get("delta_label") or ""

    range_min  = float(row["range_min"])  if row.get("range_min")  is not None else 0.0
    range_max  = float(row["range_max"])  if row.get("range_max")  is not None else 100.0
    target_min = float(row["target_min"]) if row.get("target_min") is not None else None
    target_max = float(row["target_max"]) if row.get("target_max") is not None else None

    # Spend KPIs (ai-cost) store their kpi_summary row in raw dollars, same as
    # the per-use-case data (unlike revenue/nps/efficiency, which are %/pts,
    # not dollars) — scale to millions once here so every downstream consumer
    # (status calc, formatting, tile fields) is unchanged.
    if meta["is_spend"]:
        actual, plan, delta = _dollars_to_millions(actual), _dollars_to_millions(plan), _dollars_to_millions(delta)
        range_min, range_max = _dollars_to_millions(range_min), _dollars_to_millions(range_max)
        target_min, target_max = _dollars_to_millions(target_min), _dollars_to_millions(target_max)

    status, status_label = _compute_status(kpi_id, actual, plan, meta, target_min, target_max)

    tile: dict = {
        "value":        _fmt_value(kpi_id, actual),
        "delta":        _fmt_delta(kpi_id, delta),
        "deltaLabel":   delta_label,
        "planDisplay":  _fmt_value(kpi_id, plan),
        "current":      actual,
        "status":       status,
        "statusLabel":  status_label,
        "rangeMin":     range_min,
        "rangeMax":     range_max,
    }

    if meta["is_spend"]:
        tile["planValue"] = plan
        tile["targetMax"] = target_max
    else:
        tile["planCurrent"] = plan
        tile["targetMin"]   = target_min
        tile["targetMax"]   = target_max
        lbl = _fmt_plan_label(kpi_id, plan)
        if lbl:
            tile["planLabel"] = lbl

    return tile


# ── Overview data fetchers ────────────────────────────────────────────────────

def fetch_available_years(creds) -> list[int]:
    """Distinct fiscal years present in the data, newest first."""
    sql = f"""
        SELECT DISTINCT fiscal_year FROM `{PROJECT_ID}.{DATASET}.ai_amb_kpi_summary`
        ORDER BY fiscal_year DESC
    """
    rows = _run_raw(sql, creds)
    return [int(r["fiscal_year"]) for r in rows]


def _resolve_fiscal_year(fiscal_year: Optional[int], creds) -> int:
    if fiscal_year is not None:
        return fiscal_year
    years = fetch_available_years(creds)
    if not years:
        raise ValueError("No fiscal_year data found in ai_amb_kpi_summary")
    return years[0]  # newest, since fetch_available_years orders DESC


def fetch_available_periods(fiscal_year: Optional[int], creds) -> list[str]:
    """Periods with data for the given fiscal year (defaults to the latest
    year when omitted), in canonical order (YTD, Q1..Q4)."""
    fiscal_year = _resolve_fiscal_year(fiscal_year, creds)
    sql = f"""
        SELECT DISTINCT period FROM `{PROJECT_ID}.{DATASET}.ai_amb_kpi_summary`
        WHERE fiscal_year = {int(fiscal_year)}
    """
    rows = _run_raw(sql, creds)
    found = {r["period"] for r in rows}
    return [p for p in PERIOD_ORDER if p in found]


def fetch_years_and_periods(creds) -> tuple[list[int], dict[int, list[str]]]:
    """Single-query variant of fetch_available_years + fetch_available_periods
    (one per year) — used by /api/overview/years so the frontend can gate the
    period tabs for every year without a separate round trip per year switch."""
    sql = f"""
        SELECT DISTINCT fiscal_year, period FROM `{PROJECT_ID}.{DATASET}.ai_amb_kpi_summary`
        ORDER BY fiscal_year DESC
    """
    rows = _run_raw(sql, creds)
    periods_by_year: dict[int, set[str]] = {}
    for r in rows:
        periods_by_year.setdefault(int(r["fiscal_year"]), set()).add(r["period"])
    ordered = {fy: [p for p in PERIOD_ORDER if p in periods] for fy, periods in periods_by_year.items()}
    years = sorted(ordered.keys(), reverse=True)
    return years, ordered


def fetch_kpi_summary(period: str, fiscal_year: int, creds) -> list[dict]:
    if period not in VALID_PERIODS:
        raise ValueError(f"Invalid period '{period}'. Must be one of {VALID_PERIODS}")
    sql = f"""
        SELECT kpi_id, actual_value, plan_value, actual_delta, delta_label,
               range_min, range_max, target_min, target_max
        FROM `{PROJECT_ID}.{DATASET}.ai_amb_kpi_summary`
        WHERE period = '{period}' AND fiscal_year = {int(fiscal_year)}
    """
    return _run_raw(sql, creds)


def fetch_kpi_breakdown(period: str, fiscal_year: int, creds) -> list[dict]:
    if period not in VALID_PERIODS:
        raise ValueError(f"Invalid period '{period}'. Must be one of {VALID_PERIODS}")
    sql = f"""
        SELECT kpi_id, dimension_type, dimension_name, actual_value, plan_value, display_rank,
               current_phase, functional_area, revenue_actual_dollars, revenue_plan_dollars,
               revenue_notes, nps_notes, efficiency_notes
        FROM `{PROJECT_ID}.{DATASET}.ai_amb_kpi_breakdown_v`
        WHERE period = '{period}' AND fiscal_year = {int(fiscal_year)}
        ORDER BY kpi_id, dimension_type, actual_value DESC
    """
    return _run_raw(sql, creds)


def fetch_investment(period: str, fiscal_year: int, creds) -> list[dict]:
    if period not in VALID_PERIODS:
        raise ValueError(f"Invalid period '{period}'. Must be one of {VALID_PERIODS}")
    sql = f"""
        SELECT dimension_type, dimension_name, actual_amount, plan_amount, kpi_tag, display_rank,
               description, csg, functional_area, current_phase,
               revenue_notes, nps_notes, efficiency_notes
        FROM `{PROJECT_ID}.{DATASET}.ai_amb_investment_breakdown_v`
        WHERE period = '{period}' AND fiscal_year = {int(fiscal_year)}
        ORDER BY dimension_type, actual_amount DESC
    """
    return _run_raw(sql, creds)


def build_overview_response(period: str, creds, fiscal_year: Optional[int] = None) -> dict:
    """Fetches BQ data and assembles the full overview API response.

    fiscal_year defaults to the latest year present in the data when omitted.
    """
    fiscal_year = _resolve_fiscal_year(fiscal_year, creds)

    cache_key = f"{fiscal_year}:{period}"
    cached = _OVERVIEW_CACHE.get(cache_key)
    if cached:
        ts, payload = cached
        if time.time() - ts < _OVERVIEW_CACHE_TTL:
            return payload

    # Run the three BigQuery reads in parallel to reduce end-to-end latency
    with ThreadPoolExecutor(max_workers=3) as pool:
        fut_kpi = pool.submit(fetch_kpi_summary,   period, fiscal_year, creds)
        fut_inv = pool.submit(fetch_investment,     period, fiscal_year, creds)
        fut_brk = pool.submit(fetch_kpi_breakdown,  period, fiscal_year, creds)
        kpi_rows      = fut_kpi.result()
        inv_rows      = fut_inv.result()
        breakdown_rows = fut_brk.result()

    # Build kpi tiles in canonical order
    kpi_by_id  = {r["kpi_id"]: r for r in kpi_rows}
    kpis = []
    for kpi_id in KPI_ORDER:
        row  = kpi_by_id.get(kpi_id)
        meta = TILE_META[kpi_id]
        if row:
            kpis.append(_build_tile_val(kpi_id, row, meta))
        else:
            logger.warning("No BQ row found for kpi_id=%s period=%s", kpi_id, period)
            kpis.append({
                "value": "—", "delta": "—", "deltaLabel": "", "current": 0,
                "status": "in-band", "statusLabel": "NO DATA",
            })

    # Partition investment rows by dimension_type
    by_category: list[dict] = []
    by_use_case: list[dict] = []
    by_vendor:   list[dict] = []

    for r in inv_rows:
        dt = r.get("dimension_type", "")
        if dt == "category":
            by_category.append({
                "label":  r["dimension_name"],
                "amount": _dollars_to_millions(r["actual_amount"]) or 0,
                "plan":   _dollars_to_millions(r.get("plan_amount")),
            })
        elif dt == "use_case":
            rank = r.get("display_rank")
            by_use_case.append({
                "rank":            f"{int(rank):02d}" if rank is not None else "—",
                "name":            r["dimension_name"],
                "kpi":             r.get("kpi_tag") or "",
                "amount":          _dollars_to_millions(r["actual_amount"]) or 0,
                "plan":            _dollars_to_millions(r.get("plan_amount")),
                "description":     r.get("description") or None,
                "csg":             r.get("csg") or None,
                "functionalArea":  r.get("functional_area") or None,
                "currentPhase":    r.get("current_phase") or None,
                "revenueNotes":    r.get("revenue_notes") or None,
                "npsNotes":        r.get("nps_notes") or None,
                "efficiencyNotes": r.get("efficiency_notes") or None,
            })
        elif dt == "vendor":
            by_vendor.append({
                "label":  r["dimension_name"],
                "amount": _dollars_to_millions(r["actual_amount"]) or 0,
                "plan":   _dollars_to_millions(r.get("plan_amount")),
            })

    # Partition kpi_breakdown rows by kpi_id and dimension_type
    kpi_breakdown: dict = {
        "revenue":    {"byCategory": [], "byUseCase": [], "byVendor": []},
        "nps":        {"byCategory": [], "byUseCase": [], "byVendor": []},
        "efficiency": {"byCategory": [], "byUseCase": [], "byVendor": []},
    }
    for r in breakdown_rows:
        kid = r.get("kpi_id", "")
        dt  = r.get("dimension_type", "")
        if kid not in kpi_breakdown:
            continue
        item = {
            "label":           r["dimension_name"],
            "value":           float(r["actual_value"] or 0),
            "plan":            float(r["plan_value"] or 0) if r.get("plan_value") is not None else None,
            "rank":            f"{int(r['display_rank']):02d}" if r.get("display_rank") is not None else None,
            "currentPhase":    r.get("current_phase") or None,
            "functionalArea":  r.get("functional_area") or None,
            "dollarValue":     _dollars_to_millions(r.get("revenue_actual_dollars")),
            "dollarPlan":      _dollars_to_millions(r.get("revenue_plan_dollars")),
            "revenueNotes":    r.get("revenue_notes") or None,
            "npsNotes":        r.get("nps_notes") or None,
            "efficiencyNotes": r.get("efficiency_notes") or None,
        }
        target = kpi_breakdown[kid]
        if dt == "category":
            target["byCategory"].append(item)
        elif dt == "use_case":
            target["byUseCase"].append(item)
        elif dt == "vendor":
            target["byVendor"].append(item)

    payload = {
        "fiscalYear": fiscal_year,
        "kpis": kpis,
        "investment": {
            "byCategory": by_category,
            "byUseCase":  by_use_case,
            "byVendor":   by_vendor,
        },
        "kpiBreakdown": kpi_breakdown,
    }
    _OVERVIEW_CACHE[cache_key] = (time.time(), payload)
    return payload
