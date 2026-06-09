"""NL→SQL query route — dormant until AI features are enabled.

SQLite / glossary dependency removed. Glossary context is passed as an empty
list; functionality is identical once VITE_ENABLE_AI_FEATURES is turned on.
"""
from fastapi import APIRouter, HTTPException
from typing import Optional
from pydantic import BaseModel
from schemas import QueryRequest, QueryResponse, RefineRequest
from auth import get_request_token
import gemini_client
import bigquery_client

router = APIRouter(prefix="/api/query", tags=["query"])


class SqlRequest(BaseModel):
    sql: str


@router.post("/sql", response_model=QueryResponse)
async def run_sql_query(req: SqlRequest):
    try:
        data = bigquery_client.run_query(req.sql.strip())
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"BigQuery error: {str(e)}")

    first = data[0] if data else {}
    num_keys = [k for k, v in first.items() if isinstance(v, (int, float)) and not isinstance(v, bool)]
    str_keys = [k for k in first if k not in num_keys]
    x_axis = str_keys[0] if str_keys else (list(first.keys())[0] if first else None)

    return QueryResponse(
        sql=req.sql.strip(),
        chart_type="table",
        title="SQL Result",
        x_axis=x_axis,
        y_axis=num_keys[:6],
        color_field=None,
        stacked=False,
        dual_axis=False,
        secondary_y=None,
        ai_description="",
        data=data,
    )


@router.post("", response_model=QueryResponse)
async def run_nl_query(req: QueryRequest):
    try:
        widget_def = gemini_client.generate_widget(req.nl_query, [], None)
    except Exception as e:
        msg = str(e)
        if "not initialised" in msg or "VERTEX_AI_PROJECT" in msg:
            raise HTTPException(status_code=503, detail="Vertex AI is not configured.")
        if "PERMISSION_DENIED" in msg or "permission denied" in msg.lower():
            raise HTTPException(status_code=403, detail="Vertex AI access denied.")
        raise HTTPException(status_code=500, detail=f"AI error: {msg}")

    bq_error: str | None = None
    data: list[dict] = []
    try:
        data = bigquery_client.run_query(widget_def["sql"])
    except Exception as e:
        bq_error = str(e)

    if not bq_error and not data:
        fixed = gemini_client.fix_widget_sql(widget_def, None)
        if fixed and fixed.get("sql"):
            try:
                data = bigquery_client.run_query(fixed["sql"])
                if data:
                    widget_def = fixed
            except Exception:
                pass

    return QueryResponse(
        sql=widget_def.get("sql", ""),
        chart_type=widget_def.get("chart_type", "table"),
        title=widget_def.get("title", req.nl_query),
        x_axis=widget_def.get("x_axis"),
        y_axis=widget_def.get("y_axis", []),
        color_field=widget_def.get("color_field"),
        stacked=widget_def.get("stacked", False),
        dual_axis=widget_def.get("dual_axis", False),
        secondary_y=widget_def.get("secondary_y"),
        ai_description=widget_def.get("ai_description", ""),
        data=data,
        error=bq_error,
    )


@router.post("/refine", response_model=QueryResponse)
async def refine_query(req: RefineRequest):
    try:
        widget_def = gemini_client.refine_widget(req.sql, req.nl_modification, [], None)
    except Exception as e:
        msg = str(e)
        if "not initialised" in msg or "VERTEX_AI_PROJECT" in msg:
            raise HTTPException(status_code=503, detail="Vertex AI is not configured.")
        if "PERMISSION_DENIED" in msg or "permission denied" in msg.lower():
            raise HTTPException(status_code=403, detail="Vertex AI access denied.")
        raise HTTPException(status_code=500, detail=f"AI error: {msg}")

    bq_error: str | None = None
    data: list[dict] = []
    try:
        data = bigquery_client.run_query(widget_def["sql"])
    except Exception as e:
        bq_error = str(e)

    return QueryResponse(
        sql=widget_def.get("sql", ""),
        chart_type=widget_def.get("chart_type", "table"),
        title=widget_def.get("title", ""),
        x_axis=widget_def.get("x_axis"),
        y_axis=widget_def.get("y_axis", []),
        color_field=widget_def.get("color_field"),
        stacked=widget_def.get("stacked", False),
        dual_axis=widget_def.get("dual_axis", False),
        secondary_y=widget_def.get("secondary_y"),
        ai_description=widget_def.get("ai_description", ""),
        data=data,
        error=bq_error,
    )
