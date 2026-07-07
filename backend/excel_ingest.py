"""Parses and validates the admin-uploaded Excel workbook before it is loaded
into BigQuery. Validation is exhaustive (all rows/sheets checked, not fail-fast)
so a single response can show every problem in the file at once.
"""

import io
import logging
import re
from datetime import datetime
from typing import Any, Optional

import pandas as pd
from pydantic import BaseModel, ValidationError, field_validator, model_validator

from schemas import RowError

logger = logging.getLogger(__name__)

KPI_SHEET_NAME = "KPI Cards"
USE_CASE_SHEET_NAME = "Use Case Detail"

# Required upload filename convention: AI_Ambitions_FY<YY>_<Period>_<YYYYMMDD>.xlsx
# e.g. AI_Ambitions_FY26_YTD_20260822.xlsx (fiscal_year = 2000 + YY).
FILENAME_PATTERN = re.compile(
    r"^AI_Ambitions_FY(?P<fy>\d{2})_(?P<period>YTD|Q[1-4])_(?P<date>\d{8})\.xlsx$"
)
FILENAME_CONVENTION_HELP = (
    "Filename must match AI_Ambitions_FY<YY>_<Period>_<YYYYMMDD>.xlsx "
    "(e.g. AI_Ambitions_FY26_YTD_20260822.xlsx)"
)


def parse_filename(filename: str) -> tuple[Optional[tuple[int, str]], Optional[str]]:
    """Validates the upload filename convention. Returns ((fiscal_year, period), None)
    on success, or (None, error_message) if the name is malformed."""
    m = FILENAME_PATTERN.match(filename)
    if not m:
        return None, f"{FILENAME_CONVENTION_HELP} — got '{filename}'"

    date_str = m.group("date")
    try:
        year, month, day = int(date_str[0:4]), int(date_str[4:6]), int(date_str[6:8])
        datetime(year, month, day)
    except ValueError:
        return None, f"'{date_str}' in the filename is not a valid YYYYMMDD date"

    fiscal_year = 2000 + int(m.group("fy"))
    period = m.group("period")
    return (fiscal_year, period), None

VALID_PERIODS = {"YTD", "Q1", "Q2", "Q3", "Q4"}
VALID_KPI_IDS = {"revenue", "nps", "efficiency", "ai-cost"}
VALID_PHASES = {"Planning", "Pilot", "Scaling", "Production"}

# Column order mirrors the CREATE TABLE statements in bigquery/schema.sql
# (excluding update_ts, which is stamped server-side at load time).
KPI_COLUMNS = [
    "fiscal_year", "period", "kpi_id", "actual_value", "plan_value", "actual_delta",
    "delta_label", "range_min", "range_max", "target_min", "target_max",
]

USE_CASE_COLUMNS = [
    "fiscal_year", "period", "use_case", "description", "csg", "functional_area",
    "cost_actual", "cost_plan",
    "revenue_actual", "revenue_plan", "revenue_actual_dollars", "revenue_plan_dollars", "revenue_notes",
    "nps_actual", "nps_plan", "nps_notes",
    "efficiency_actual", "efficiency_plan", "efficiency_notes",
    "current_phase",
]


class KPISummaryRow(BaseModel):
    fiscal_year: int
    period: str
    kpi_id: str
    actual_value: float
    plan_value: Optional[float] = None
    actual_delta: Optional[float] = None
    delta_label: Optional[str] = None
    range_min: Optional[float] = None
    range_max: Optional[float] = None
    target_min: Optional[float] = None
    target_max: Optional[float] = None

    @field_validator("period")
    @classmethod
    def _valid_period(cls, v: str) -> str:
        if v not in VALID_PERIODS:
            raise ValueError(f"must be one of {sorted(VALID_PERIODS)}")
        return v

    @field_validator("kpi_id")
    @classmethod
    def _valid_kpi_id(cls, v: str) -> str:
        if v not in VALID_KPI_IDS:
            raise ValueError(f"must be one of {sorted(VALID_KPI_IDS)}")
        return v

    @model_validator(mode="after")
    def _check_ranges(self) -> "KPISummaryRow":
        if self.range_min is not None and self.range_max is not None and self.range_min > self.range_max:
            raise ValueError("range_min must be <= range_max")
        if self.target_min is not None and self.target_max is not None and self.target_min > self.target_max:
            raise ValueError("target_min must be <= target_max")
        return self


class UseCaseRow(BaseModel):
    fiscal_year: int
    period: str
    use_case: str
    description: Optional[str] = None
    csg: Optional[str] = None
    functional_area: Optional[str] = None
    cost_actual: Optional[float] = None
    cost_plan: Optional[float] = None
    revenue_actual: Optional[float] = None
    revenue_plan: Optional[float] = None
    revenue_actual_dollars: Optional[float] = None
    revenue_plan_dollars: Optional[float] = None
    revenue_notes: Optional[str] = None
    nps_actual: Optional[float] = None
    nps_plan: Optional[float] = None
    nps_notes: Optional[str] = None
    efficiency_actual: Optional[float] = None
    efficiency_plan: Optional[float] = None
    efficiency_notes: Optional[str] = None
    current_phase: Optional[str] = None

    @field_validator("use_case")
    @classmethod
    def _non_empty_use_case(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("must not be blank")
        return v

    @field_validator("period")
    @classmethod
    def _valid_period(cls, v: str) -> str:
        if v not in VALID_PERIODS:
            raise ValueError(f"must be one of {sorted(VALID_PERIODS)}")
        return v

    @field_validator("current_phase")
    @classmethod
    def _valid_phase(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_PHASES:
            raise ValueError(f"must be one of {sorted(VALID_PHASES)}")
        return v

    @model_validator(mode="after")
    def _check_non_negative(self) -> "UseCaseRow":
        for field in ("cost_actual", "cost_plan"):
            val = getattr(self, field)
            if val is not None and val < 0:
                raise ValueError(f"{field} must be non-negative")
        return self


class IngestResult(BaseModel):
    ok: bool
    errors: list[RowError] = []
    kpi_rows: list[dict[str, Any]] = []
    use_case_rows: list[dict[str, Any]] = []
    periods: list[dict[str, Any]] = []  # [{"fiscal_year": 2026, "period": "Q1"}, ...]


def _normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [str(c).strip() for c in df.columns]
    return df


def _find_sheet(sheets: dict[str, pd.DataFrame], name: str) -> Optional[str]:
    target = name.strip().lower()
    for key in sheets:
        if key.strip().lower() == target:
            return key
    return None


def _check_columns(df: pd.DataFrame, expected: list[str], sheet_label: str) -> list[RowError]:
    errors = []
    actual = set(df.columns)
    expected_set = set(expected)
    for missing in sorted(expected_set - actual):
        errors.append(RowError(sheet=sheet_label, column=missing, message="required column is missing"))
    for extra in sorted(actual - expected_set):
        errors.append(RowError(sheet=sheet_label, column=extra, message="unrecognized column"))
    return errors


def _clean_value(v: Any) -> Any:
    if pd.isna(v):
        return None
    if isinstance(v, str):
        v = v.strip()
        return v if v else None
    return v


def _validate_rows(df: pd.DataFrame, model: type[BaseModel], sheet_label: str) -> tuple[list[tuple[int, dict]], list[RowError]]:
    """Returns [(excel_row_number, validated_row_dict), ...] plus any errors.

    Fully-blank rows (e.g. trailing empty Excel rows) are skipped silently —
    they aren't data, so they shouldn't be reported as validation failures.
    """
    rows: list[tuple[int, dict]] = []
    errors: list[RowError] = []
    for i, raw in enumerate(df.to_dict(orient="records")):
        excel_row = i + 2  # header is row 1, data starts at row 2
        cleaned = {k: _clean_value(v) for k, v in raw.items()}
        if all(v is None for v in cleaned.values()):
            continue
        try:
            validated = model.model_validate(cleaned)
        except ValidationError as exc:
            for err in exc.errors():
                col = err["loc"][0] if err["loc"] else None
                errors.append(RowError(
                    sheet=sheet_label, row=excel_row,
                    column=str(col) if col else None, message=err["msg"],
                ))
            continue
        rows.append((excel_row, validated.model_dump()))
    return rows, errors


def _check_duplicates(rows: list[tuple[int, dict]], key_fields: list[str], sheet_label: str) -> list[RowError]:
    seen: dict[tuple, int] = {}
    errors = []
    for excel_row, row in rows:
        key = tuple(row[f] for f in key_fields)
        if key in seen:
            errors.append(RowError(
                sheet=sheet_label, row=excel_row,
                message=f"duplicate {'+'.join(key_fields)} {key} (first seen at row {seen[key]})",
            ))
        else:
            seen[key] = excel_row
    return errors


def parse_and_validate(contents: bytes, expected_period: Optional[tuple[int, str]] = None) -> IngestResult:
    """expected_period, when given, is the (fiscal_year, period) declared by the
    upload filename (see parse_filename) — the workbook must contain data for
    exactly that period and no other."""
    try:
        sheets = pd.read_excel(io.BytesIO(contents), sheet_name=None)
    except Exception as exc:
        return IngestResult(ok=False, errors=[RowError(sheet="workbook", message=f"could not read Excel file: {exc}")])

    errors: list[RowError] = []

    kpi_key = _find_sheet(sheets, KPI_SHEET_NAME)
    use_case_key = _find_sheet(sheets, USE_CASE_SHEET_NAME)

    if kpi_key is None:
        errors.append(RowError(sheet=KPI_SHEET_NAME, message="required sheet is missing"))
    if use_case_key is None:
        errors.append(RowError(sheet=USE_CASE_SHEET_NAME, message="required sheet is missing"))

    # Strict about sheets, same as columns — an extra tab (leftover draft,
    # notes, a copy-pasted sheet) is rejected rather than silently ignored.
    known_keys = {kpi_key, use_case_key}
    for extra in sorted(name for name in sheets if name not in known_keys):
        errors.append(RowError(
            sheet=extra,
            message=f"unrecognized sheet — workbook must contain only '{KPI_SHEET_NAME}' and '{USE_CASE_SHEET_NAME}'",
        ))

    if errors:
        return IngestResult(ok=False, errors=errors)

    kpi_df = _normalize_columns(sheets[kpi_key])
    use_case_df = _normalize_columns(sheets[use_case_key])

    errors += _check_columns(kpi_df, KPI_COLUMNS, KPI_SHEET_NAME)
    errors += _check_columns(use_case_df, USE_CASE_COLUMNS, USE_CASE_SHEET_NAME)

    # A column mismatch means row-level validation can't be trusted (a missing
    # required column would just look like every row has a blank value), so
    # surface the column problem first rather than drowning it in row errors.
    if errors:
        return IngestResult(ok=False, errors=errors)

    kpi_rows, kpi_errors = _validate_rows(kpi_df, KPISummaryRow, KPI_SHEET_NAME)
    use_case_rows, use_case_errors = _validate_rows(use_case_df, UseCaseRow, USE_CASE_SHEET_NAME)
    errors += kpi_errors
    errors += use_case_errors

    errors += _check_duplicates(kpi_rows, ["fiscal_year", "period", "kpi_id"], KPI_SHEET_NAME)
    errors += _check_duplicates(use_case_rows, ["fiscal_year", "period", "use_case"], USE_CASE_SHEET_NAME)

    kpi_periods = {(r["fiscal_year"], r["period"]) for _, r in kpi_rows}
    use_case_periods = {(r["fiscal_year"], r["period"]) for _, r in use_case_rows}

    for fy, period in sorted(kpi_periods - use_case_periods):
        errors.append(RowError(
            sheet="cross-sheet",
            message=f"fiscal_year={fy} period={period} present in '{KPI_SHEET_NAME}' but missing from '{USE_CASE_SHEET_NAME}'",
        ))
    for fy, period in sorted(use_case_periods - kpi_periods):
        errors.append(RowError(
            sheet="cross-sheet",
            message=f"fiscal_year={fy} period={period} present in '{USE_CASE_SHEET_NAME}' but missing from '{KPI_SHEET_NAME}'",
        ))

    all_periods = kpi_periods | use_case_periods
    if expected_period is not None and all_periods != {expected_period}:
        errors.append(RowError(
            sheet="filename",
            message=(
                f"Filename declares fiscal_year={expected_period[0]} period={expected_period[1]}, "
                f"but the workbook contains data for {sorted(all_periods)}"
            ),
        ))

    if errors:
        return IngestResult(ok=False, errors=errors)

    periods = [{"fiscal_year": fy, "period": p} for fy, p in sorted(kpi_periods | use_case_periods)]
    return IngestResult(
        ok=True,
        kpi_rows=[r for _, r in kpi_rows],
        use_case_rows=[r for _, r in use_case_rows],
        periods=periods,
    )
