import logging
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
import bigquery_client
from auth import get_bq_credentials

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/overview", tags=["overview"])

VALID_PERIODS = {"YTD", "Q1", "Q2", "Q3", "Q4"}


@router.get("/summary")
async def get_summary(period: str = Query(default="YTD"), fiscal_year: Optional[int] = Query(default=None)):
    """Return KPI tiles and investment breakdown for the requested period/fiscal year.

    fiscal_year defaults to the latest year present in BigQuery when omitted.

    Response shape:
    {
      "fiscalYear": 2026,
      "kpis": [TileVal x 4],          # ordered: revenue, nps, efficiency, ai-cost
      "investment": {
        "byCategory": [BarItem, ...],
        "byUseCase":  [UseCaseItem, ...],
        "byVendor":   [BarItem, ...]
      }
    }
    """
    period = period.upper()
    if period not in VALID_PERIODS:
        raise HTTPException(status_code=400, detail=f"Invalid period '{period}'. Must be one of {sorted(VALID_PERIODS)}")

    try:
        creds = get_bq_credentials()
        return bigquery_client.build_overview_response(period, creds, fiscal_year=fiscal_year)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Failed to fetch overview data for period=%s fiscal_year=%s", period, fiscal_year)
        raise HTTPException(status_code=500, detail=f"BigQuery error: {exc}")


@router.get("/periods")
async def get_periods(fiscal_year: Optional[int] = Query(default=None)):
    """Returns the periods that have data for the given fiscal year (defaults
    to the latest year present in BigQuery when omitted)."""
    try:
        creds = get_bq_credentials()
        periods = bigquery_client.fetch_available_periods(fiscal_year, creds)
        return {"periods": periods}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Failed to fetch available periods for fiscal_year=%s", fiscal_year)
        raise HTTPException(status_code=500, detail=f"BigQuery error: {exc}")


@router.get("/years")
async def get_years():
    """Returns the distinct fiscal years present in BigQuery (newest first)
    plus which periods have data for each — one query, one round trip, so the
    frontend can gate the period tabs for any year without re-fetching on
    every year switch.

    The frontend only shows the fiscal-year dropdown when this returns more
    than one year — until then there's nothing to switch between.
    """
    try:
        creds = get_bq_credentials()
        years, periods_by_year = bigquery_client.fetch_years_and_periods(creds)
        return {
            "years": years,
            "periodsByYear": {str(y): periods_by_year[y] for y in years},
        }
    except Exception as exc:
        logger.exception("Failed to fetch available fiscal years")
        raise HTTPException(status_code=500, detail=f"BigQuery error: {exc}")
