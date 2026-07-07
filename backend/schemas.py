from pydantic import BaseModel
from typing import Optional, Any


class QueryRequest(BaseModel):
    nl_query: str


class RefineRequest(BaseModel):
    sql: str
    nl_modification: str


class QueryResponse(BaseModel):
    sql: str
    chart_type: str
    title: str
    x_axis: Optional[str] = None
    y_axis: list[str] = []
    color_field: Optional[str] = None
    stacked: bool = False
    dual_axis: bool = False
    secondary_y: Optional[str] = None
    ai_description: str
    data: list[dict[str, Any]] = []
    error: Optional[str] = None


class PDFRequest(BaseModel):
    tab_name: str
    title: str
    widgets: list[dict[str, Any]]


class RowError(BaseModel):
    sheet: str
    row: Optional[int] = None
    column: Optional[str] = None
    message: str


class ImportResponse(BaseModel):
    filename: str
    gcs_path: str
    success: bool
    periods_replaced: list[dict[str, Any]] = []
    kpi_rows_loaded: int = 0
    use_case_rows_loaded: int = 0
    errors: list[RowError] = []
    warning: Optional[str] = None
