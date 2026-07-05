import os
import logging
import time
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

# ── KPI metadata (mirrors TILE_META in frontend OverviewTab.tsx) ──────────────
# range_min/max: the full scale of the range bar
# target_min/max: the "good" target band (non-spend tiles only)
# is_spend: True for the AI Cost tile; uses plan as a budget cap, not a band
# fmt: format template used to display the value string

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
_OVERVIEW_CACHE_TTL = 0.0  # disabled — always fetch fresh from BigQuery


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

def _fmt_value(kpi_id: str, val: float) -> str:
    if kpi_id == "revenue":
        return f"{val:.1f}%"
    if kpi_id == "nps":
        return f"{val:.1f}pts"
    if kpi_id == "efficiency":
        return f"{val:.0f}%"
    if kpi_id == "ai-cost":
        return f"${val:.1f}M"
    return str(val)


def _fmt_delta(kpi_id: str, delta: float) -> str:
    if kpi_id == "ai-cost":
        sign = "−" if delta < 0 else "+"   # U+2212 minus sign
        return f"{sign}${abs(delta):.1f}M"
    sign = "+" if delta >= 0 else ""
    if kpi_id in ("revenue", "nps"):
        return f"{sign}{delta:.1f}"
    return f"{sign}{delta:.0f}"


def _fmt_plan_label(kpi_id: str, plan_val: float) -> str | None:
    if kpi_id == "revenue":
        return f"Plan {plan_val:.1f}%"
    if kpi_id == "nps":
        return f"Plan {plan_val:.1f}pts"
    if kpi_id == "efficiency":
        return f"Plan {plan_val:.0f}%"
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


def _build_tile_val(kpi_id: str, row: dict, meta: dict) -> dict:
    actual = float(row.get("actual_value") or 0)
    plan   = float(row.get("plan_value")   or 0)
    delta  = float(row.get("actual_delta") or 0)
    delta_label = row.get("delta_label") or ""

    range_min  = float(row["range_min"])  if row.get("range_min")  is not None else 0.0
    range_max  = float(row["range_max"])  if row.get("range_max")  is not None else 100.0
    target_min = float(row["target_min"]) if row.get("target_min") is not None else None
    target_max = float(row["target_max"]) if row.get("target_max") is not None else None

    status, status_label = _compute_status(kpi_id, actual, plan, meta, target_min, target_max)

    tile: dict = {
        "value":       _fmt_value(kpi_id, actual),
        "delta":       _fmt_delta(kpi_id, delta),
        "deltaLabel":  delta_label,
        "current":     actual,
        "status":      status,
        "statusLabel": status_label,
        "rangeMin":    range_min,
        "rangeMax":    range_max,
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
                "amount": float(r["actual_amount"] or 0),
                "plan":   float(r["plan_amount"] or 0) if r.get("plan_amount") is not None else None,
            })
        elif dt == "use_case":
            rank = r.get("display_rank")
            by_use_case.append({
                "rank":            f"{int(rank):02d}" if rank is not None else "—",
                "name":            r["dimension_name"],
                "kpi":             r.get("kpi_tag") or "",
                "amount":          float(r["actual_amount"] or 0),
                "plan":            float(r["plan_amount"] or 0) if r.get("plan_amount") is not None else None,
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
                "amount": float(r["actual_amount"] or 0),
                "plan":   float(r["plan_amount"] or 0) if r.get("plan_amount") is not None else None,
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
            "dollarValue":     float(r["revenue_actual_dollars"]) if r.get("revenue_actual_dollars") is not None else None,
            "dollarPlan":      float(r["revenue_plan_dollars"])   if r.get("revenue_plan_dollars")   is not None else None,
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

    return {
        "fiscalYear": fiscal_year,
        "kpis": kpis,
        "investment": {
            "byCategory": by_category,
            "byUseCase":  by_use_case,
            "byVendor":   by_vendor,
        },
        "kpiBreakdown": kpi_breakdown,
    }


    # cache population handled above after building 'payload' — but keep this
    # function return path simple. (If additional caching logic is desired
    # populate _OVERVIEW_CACHE before returning.)
