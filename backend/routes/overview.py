import logging
from fastapi import APIRouter, HTTPException, Query
import bigquery_client
from auth import get_bq_credentials

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/overview", tags=["overview"])

VALID_PERIODS = {"YTD", "Q1", "Q2", "Q3", "Q4"}


@router.get("/summary")
async def get_summary(period: str = Query(default="YTD")):
    """Return KPI tiles and investment breakdown for the requested period.

    Response shape:
    {
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
        return bigquery_client.build_overview_response(period, creds)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Failed to fetch overview data for period=%s", period)
        raise HTTPException(status_code=500, detail=f"BigQuery error: {exc}")


@router.get("/periods")
async def get_periods():
    """Returns the list of available periods (static for now)."""
    return ["YTD", "Q1", "Q2", "Q3", "Q4"]
