-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — BigQuery Schema (clean start)
-- Dataset: ai_ambitions  (create with: bq mk --dataset PROJECT:ai_ambitions)
--
-- Run order:
--   1. schema.sql    — this file (DROP + CREATE)
--   2. seed_data.sql — INSERT statements
--
-- Table inventory (3 tables):
--   ai_amb_kpi_summary    — headline KPI tiles (fiscal_year × period × kpi_id)
--   ai_amb_use_case_data  — flat fact: all use-case metrics per fiscal_year × period
--   ai_amb_upload_audit   — audit log of admin Excel-upload attempts
--
-- View inventory (2 views):
--   ai_amb_investment_breakdown_v  — use-case spend rows
--   ai_amb_kpi_breakdown_v         — use-case KPI rows
--
-- Replace `ai_ambitions` with your `project_id.dataset_id` as needed.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. Drop views first (views depend on tables) ─────────────────────────────

DROP VIEW IF EXISTS `ai_ambitions.ai_amb_kpi_breakdown_v`;
DROP VIEW IF EXISTS `ai_ambitions.ai_amb_investment_breakdown_v`;
DROP VIEW IF EXISTS `ai_ambitions.v_kpi_breakdown`;
DROP VIEW IF EXISTS `ai_ambitions.v_investment_breakdown`;


-- ── 3. Create tables ──────────────────────────────────────────────────────────

-- Table: ai_amb_kpi_summary
-- One row per (fiscal_year, period, kpi_id). Source for the four KPI headline tiles.
CREATE TABLE `ai_ambitions.ai_amb_kpi_summary` (
  fiscal_year   INT64    NOT NULL OPTIONS(description='Fiscal year, e.g. 2026 for FY26'),
  period        STRING   NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  kpi_id        STRING   NOT NULL OPTIONS(description='revenue | nps | efficiency | ai-cost'),
  actual_value  FLOAT64  NOT NULL OPTIONS(description='Metric value in display units (%, pts, or $M)'),
  plan_value    FLOAT64           OPTIONS(description='Planned / budget target in same units'),
  actual_delta  FLOAT64           OPTIONS(description='Change vs comparison; positive = improvement'),
  delta_label   STRING            OPTIONS(description='Human label for the delta, e.g. "vs Q3" or "vs plan"'),
  range_min     FLOAT64           OPTIONS(description='Range bar minimum value (display scale)'),
  range_max     FLOAT64           OPTIONS(description='Range bar maximum value (display scale)'),
  target_min    FLOAT64           OPTIONS(description='Target band lower bound (non-spend KPIs); NULL for ai-cost'),
  target_max    FLOAT64           OPTIONS(description='Target band upper bound for non-spend; budget cap for ai-cost'),
  update_ts     TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_use_case_data
-- Flat fact table: one row per (fiscal_year, period, use_case).
-- KPI columns (revenue_actual, nps_actual, efficiency_actual) are NULL
-- when the use case does not contribute to that KPI. The views filter on
-- IS NOT NULL to show only contributing use cases in each KPI drill-down.
CREATE TABLE `ai_ambitions.ai_amb_use_case_data` (
  fiscal_year        INT64     NOT NULL OPTIONS(description='Fiscal year, e.g. 2026 for FY26'),
  period             STRING    NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  use_case           STRING    NOT NULL OPTIONS(description='Use case display name'),
  description        STRING             OPTIONS(description='One-sentence description for hover tooltip'),
  csg                STRING             OPTIONS(description='Consumer segment group / business unit'),
  functional_area    STRING             OPTIONS(description='Primary function (Commerce, CX, Operations, etc.)'),
  cost_actual        FLOAT64            OPTIONS(description='Actual AI spend ($M)'),
  cost_plan          FLOAT64            OPTIONS(description='Planned spend ($M)'),
  revenue_actual         FLOAT64            OPTIONS(description='Revenue growth contribution (%); NULL = not contributing'),
  revenue_plan           FLOAT64            OPTIONS(description='Planned revenue contribution (%)'),
  revenue_actual_dollars FLOAT64            OPTIONS(description='Revenue growth contribution ($M); NULL = not contributing'),
  revenue_plan_dollars   FLOAT64            OPTIONS(description='Planned revenue contribution ($M)'),
  revenue_notes          STRING             OPTIONS(description="Free-text note for this use case's revenue contribution"),
  nps_actual         FLOAT64            OPTIONS(description='NPS improvement contribution (pts); NULL = not contributing'),
  nps_plan           FLOAT64            OPTIONS(description='Planned NPS contribution (pts)'),
  nps_notes          STRING             OPTIONS(description="Free-text note for this use case's NPS contribution"),
  efficiency_actual  FLOAT64            OPTIONS(description='Efficiency gain contribution (%); NULL = not contributing'),
  efficiency_plan    FLOAT64            OPTIONS(description='Planned efficiency contribution (%)'),
  efficiency_notes   STRING             OPTIONS(description="Free-text note for this use case's efficiency contribution"),
  current_phase      STRING             OPTIONS(description='Delivery phase: Planning | Pilot | Scaling | Production'),
  update_ts          TIMESTAMP          OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_upload_audit
-- One row per admin Excel-upload attempt (backend/routes/admin.py). The file
-- itself and full error detail also land in GCS (archive/success|failure/ +
-- .errors.json) — this table just makes that history queryable from BigQuery.
CREATE TABLE `ai_ambitions.ai_amb_upload_audit` (
  upload_ts             TIMESTAMP NOT NULL OPTIONS(description='When this upload attempt was processed'),
  uploaded_by           STRING    NOT NULL OPTIONS(description='Resolved user id/email of the uploading admin'),
  filename              STRING    NOT NULL OPTIONS(description='Original uploaded filename'),
  fiscal_year           INT64             OPTIONS(description='Declared fiscal year; NULL if the filename itself was rejected'),
  period                STRING            OPTIONS(description='Declared period; NULL if the filename itself was rejected'),
  outcome               STRING    NOT NULL OPTIONS(description='success | failure'),
  kpi_rows_loaded       INT64     NOT NULL OPTIONS(description='Rows loaded into ai_amb_kpi_summary; 0 on failure'),
  use_case_rows_loaded  INT64     NOT NULL OPTIONS(description='Rows loaded into ai_amb_use_case_data; 0 on failure'),
  error_count           INT64     NOT NULL OPTIONS(description='Number of validation/processing errors'),
  errors_json           STRING            OPTIONS(description='JSON-serialized RowError[]; NULL on success'),
  warning               STRING            OPTIONS(description='Set when data loaded but GCS archiving did not fully complete'),
  gcs_path              STRING            OPTIONS(description='gs:// path of the archived file (or the input/ orphan, in the warning case)')
);


-- ── 4. Create views ───────────────────────────────────────────────────────────

-- View: ai_amb_investment_breakdown_v
-- Feeds the AI Cost widget: all use-case spend rows.
-- kpi_tag surfaces all KPIs each use case contributes to (comma-separated).
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_investment_breakdown_v` AS

SELECT
  fiscal_year,
  period,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  COALESCE(cost_actual, 0.0) AS actual_amount,
  cost_plan            AS plan_amount,
  CASE
    WHEN revenue_actual IS NOT NULL AND nps_actual IS NOT NULL AND efficiency_actual IS NOT NULL THEN 'REVENUE,NPS,EFFICIENCY'
    WHEN revenue_actual IS NOT NULL AND nps_actual IS NOT NULL                                  THEN 'REVENUE,NPS'
    WHEN revenue_actual IS NOT NULL AND efficiency_actual IS NOT NULL                           THEN 'REVENUE,EFFICIENCY'
    WHEN nps_actual     IS NOT NULL AND efficiency_actual IS NOT NULL                           THEN 'NPS,EFFICIENCY'
    WHEN revenue_actual IS NOT NULL                                                             THEN 'REVENUE'
    WHEN nps_actual     IS NOT NULL                                                             THEN 'NPS'
    WHEN efficiency_actual IS NOT NULL                                                          THEN 'EFFICIENCY'
    ELSE ''
  END                  AS kpi_tag,
  CAST(NULL AS INT64)  AS display_rank,
  description,
  csg,
  functional_area,
  current_phase,
  revenue_notes,
  nps_notes,
  efficiency_notes
FROM `ai_ambitions.ai_amb_use_case_data`;


-- View: ai_amb_kpi_breakdown_v
-- Feeds the KPI-mode widgets: per-KPI use-case rows.
-- Use cases that do not contribute to a given KPI are excluded via IS NOT NULL filters.
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_kpi_breakdown_v` AS

SELECT
  fiscal_year,
  period,
  'revenue'            AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  revenue_actual       AS actual_value,
  revenue_plan         AS plan_value,
  CAST(NULL AS INT64)  AS display_rank,
  current_phase,
  functional_area,
  revenue_actual_dollars,
  revenue_plan_dollars,
  revenue_notes,
  nps_notes,
  efficiency_notes
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE revenue_actual IS NOT NULL

UNION ALL

SELECT
  fiscal_year,
  period,
  'nps'                AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  nps_actual           AS actual_value,
  nps_plan             AS plan_value,
  CAST(NULL AS INT64)   AS display_rank,
  current_phase,
  functional_area,
  CAST(NULL AS FLOAT64) AS revenue_actual_dollars,
  CAST(NULL AS FLOAT64) AS revenue_plan_dollars,
  revenue_notes,
  nps_notes,
  efficiency_notes
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE nps_actual IS NOT NULL

UNION ALL

SELECT
  fiscal_year,
  period,
  'efficiency'         AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  efficiency_actual    AS actual_value,
  efficiency_plan      AS plan_value,
  CAST(NULL AS INT64)   AS display_rank,
  current_phase,
  functional_area,
  CAST(NULL AS FLOAT64) AS revenue_actual_dollars,
  CAST(NULL AS FLOAT64) AS revenue_plan_dollars,
  revenue_notes,
  nps_notes,
  efficiency_notes
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE efficiency_actual IS NOT NULL;
