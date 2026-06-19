-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — BigQuery Schema (clean start)
-- Dataset: ai_ambitions  (create with: bq mk --dataset PROJECT:ai_ambitions)
--
-- Run order:
--   1. schema.sql    — this file (DROP + CREATE)
--   2. seed_data.sql — INSERT statements
--
-- Table inventory (3 tables):
--   ai_amb_kpi_summary        — headline KPI tiles (period × kpi_id)
--   ai_amb_dimension_metrics  — spend + KPI by category/vendor
--   ai_amb_use_case_data      — flat fact: all use-case metrics per period
--
-- View inventory (2 views):
--   ai_amb_investment_breakdown_v  — cost rows + use-case spend rows
--   ai_amb_kpi_breakdown_v         — KPI rows + use-case KPI rows
--
-- Replace `ai_ambitions` with your `project_id.dataset_id` as needed.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. Drop views first (views depend on tables) ─────────────────────────────

DROP VIEW IF EXISTS `ai_ambitions.ai_amb_kpi_breakdown_v`;
DROP VIEW IF EXISTS `ai_ambitions.ai_amb_investment_breakdown_v`;
DROP VIEW IF EXISTS `ai_ambitions.v_kpi_breakdown`;
DROP VIEW IF EXISTS `ai_ambitions.v_investment_breakdown`;


-- ── 2. Drop tables ────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS `ai_ambitions.ai_amb_use_case_data`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_use_case_metric`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_use_cases`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_dimension_metrics`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_kpi_summary`;
DROP TABLE IF EXISTS `ai_ambitions.ai_ambition_use_case_metrics`;
DROP TABLE IF EXISTS `ai_ambitions.ai_ambition_use_cases`;
DROP TABLE IF EXISTS `ai_ambitions.ai_ambition_kpi_breakdown`;
DROP TABLE IF EXISTS `ai_ambitions.ai_ambition_investment`;
DROP TABLE IF EXISTS `ai_ambitions.ai_ambition_kpi_summary`;


-- ── 3. Create tables ──────────────────────────────────────────────────────────

-- Table: ai_amb_kpi_summary
-- One row per (period, kpi_id). Source for the four KPI headline tiles.
CREATE TABLE `ai_ambitions.ai_amb_kpi_summary` (
  period        STRING   NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  kpi_id        STRING   NOT NULL OPTIONS(description='revenue | nps | efficiency | ai-cost'),
  actual_value  FLOAT64  NOT NULL OPTIONS(description='Metric value in display units (%, pts, or $M)'),
  plan_value    FLOAT64           OPTIONS(description='Planned / budget target in same units'),
  actual_delta  FLOAT64           OPTIONS(description='Change vs comparison; positive = improvement'),
  delta_label   STRING            OPTIONS(description='Human label for the delta, e.g. "vs Q3" or "vs plan"'),
  update_ts     TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_dimension_metrics
-- Category- and vendor-level contributions for spend and KPIs.
-- metric_id = 'cost'       → actual_value in $M
-- metric_id = 'revenue'    → actual_value in %
-- metric_id = 'nps'        → actual_value in pts
-- metric_id = 'efficiency' → actual_value in %
CREATE TABLE `ai_ambitions.ai_amb_dimension_metrics` (
  period          STRING   NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  metric_id       STRING   NOT NULL OPTIONS(description='cost | revenue | nps | efficiency'),
  dimension_type  STRING   NOT NULL OPTIONS(description='category | vendor'),
  dimension_name  STRING   NOT NULL OPTIONS(description='Human-readable label'),
  actual_value    FLOAT64  NOT NULL OPTIONS(description='Metric value in units defined by metric_id'),
  plan_value      FLOAT64           OPTIONS(description='Planned value in same units'),
  update_ts       TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_use_case_data
-- Flat fact table: one row per (period, use_case).
-- KPI columns (revenue_actual, nps_actual, efficiency_actual) are NULL
-- when the use case does not contribute to that KPI. The views filter on
-- IS NOT NULL to show only contributing use cases in each KPI drill-down.
CREATE TABLE `ai_ambitions.ai_amb_use_case_data` (
  period             STRING    NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  use_case           STRING    NOT NULL OPTIONS(description='Use case display name'),
  description        STRING             OPTIONS(description='One-sentence description for hover tooltip'),
  csg                STRING             OPTIONS(description='Consumer segment group / business unit'),
  functional_area    STRING             OPTIONS(description='Primary function (Commerce, CX, Operations, etc.)'),
  cost_actual        FLOAT64            OPTIONS(description='Actual AI spend ($M)'),
  cost_plan          FLOAT64            OPTIONS(description='Planned spend ($M)'),
  revenue_actual     FLOAT64            OPTIONS(description='Revenue growth contribution (%); NULL = not contributing'),
  revenue_plan       FLOAT64            OPTIONS(description='Planned revenue contribution (%)'),
  nps_actual         FLOAT64            OPTIONS(description='NPS improvement contribution (pts); NULL = not contributing'),
  nps_plan           FLOAT64            OPTIONS(description='Planned NPS contribution (pts)'),
  efficiency_actual  FLOAT64            OPTIONS(description='Efficiency gain contribution (%); NULL = not contributing'),
  efficiency_plan    FLOAT64            OPTIONS(description='Planned efficiency contribution (%)'),
  update_ts          TIMESTAMP          OPTIONS(description='Last refresh timestamp')
);


-- ── 4. Create views ───────────────────────────────────────────────────────────

-- View: ai_amb_investment_breakdown_v
-- Feeds the AI Cost widget: category/vendor cost dimension rows + all use-case
-- spend rows. The kpi_tag column surfaces the primary KPI for each use case
-- (used in the UseCaseWidget AI Cost mode to show a KPI badge per row).
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_investment_breakdown_v` AS

SELECT
  period,
  dimension_type,
  dimension_name,
  actual_value         AS actual_amount,
  plan_value           AS plan_amount,
  CAST(NULL AS STRING) AS kpi_tag,
  CAST(NULL AS INT64)  AS display_rank,
  CAST(NULL AS STRING) AS description,
  CAST(NULL AS STRING) AS csg,
  CAST(NULL AS STRING) AS functional_area
FROM `ai_ambitions.ai_amb_dimension_metrics`
WHERE metric_id = 'cost'

UNION ALL

SELECT
  period,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  COALESCE(cost_actual, 0.0) AS actual_amount,
  cost_plan            AS plan_amount,
  CASE
    WHEN revenue_actual    IS NOT NULL THEN 'REVENUE'
    WHEN nps_actual        IS NOT NULL THEN 'NPS'
    WHEN efficiency_actual IS NOT NULL THEN 'EFFICIENCY'
    ELSE ''
  END                  AS kpi_tag,
  CAST(NULL AS INT64)  AS display_rank,
  description,
  csg,
  functional_area
FROM `ai_ambitions.ai_amb_use_case_data`;


-- View: ai_amb_kpi_breakdown_v
-- Feeds the KPI-mode widgets: category/vendor rows for each KPI, plus per-KPI
-- use-case rows. Use cases that do not contribute to a given KPI are excluded
-- via IS NOT NULL filters on the respective KPI column.
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_kpi_breakdown_v` AS

SELECT
  period,
  metric_id            AS kpi_id,
  dimension_type,
  dimension_name,
  actual_value,
  plan_value,
  CAST(NULL AS INT64)  AS display_rank
FROM `ai_ambitions.ai_amb_dimension_metrics`
WHERE metric_id IN ('revenue', 'nps', 'efficiency')

UNION ALL

SELECT
  period,
  'revenue'            AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  revenue_actual       AS actual_value,
  revenue_plan         AS plan_value,
  CAST(NULL AS INT64)  AS display_rank
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE revenue_actual IS NOT NULL

UNION ALL

SELECT
  period,
  'nps'                AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  nps_actual           AS actual_value,
  nps_plan             AS plan_value,
  CAST(NULL AS INT64)  AS display_rank
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE nps_actual IS NOT NULL

UNION ALL

SELECT
  period,
  'efficiency'         AS kpi_id,
  'use_case'           AS dimension_type,
  use_case             AS dimension_name,
  efficiency_actual    AS actual_value,
  efficiency_plan      AS plan_value,
  CAST(NULL AS INT64)  AS display_rank
FROM `ai_ambitions.ai_amb_use_case_data`
WHERE efficiency_actual IS NOT NULL;
