-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — BigQuery Schema (clean start)
-- Dataset: ai_ambitions  (create with: bq mk --dataset PROJECT:ai_ambitions)
--
-- Run order:
--   1. schema.sql   — this file (DROP + CREATE)
--   2. seed_data.sql — INSERT statements
--
-- Each statement must be run individually in the BigQuery console, or
-- run the whole file as a script via:
--   bq query --use_legacy_sql=false < schema.sql
--
-- Replace `ai_ambitions` with your `project_id.dataset_id` as needed.
--
-- Table inventory:
--   ai_amb_kpi_summary        — headline KPI tiles (period × kpi_id)
--   ai_amb_dimension_metrics  — spend + KPI contributions by category/vendor
--                               (metric_id: 'cost' | 'revenue' | 'nps' | 'efficiency')
--   ai_amb_use_cases          — use case master list (period-independent)
--   ai_amb_use_case_metric    — all per-use-case metrics per period (wide fact)
--
-- View inventory:
--   ai_amb_investment_breakdown_v  — cost rows + derived use-case spend rows
--   ai_amb_kpi_breakdown_v         — KPI contribution rows + derived use-case KPI rows
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. Drop views first (views depend on tables) ─────────────────────────────

DROP VIEW IF EXISTS `ai_ambitions.ai_amb_kpi_breakdown_v`;
DROP VIEW IF EXISTS `ai_ambitions.ai_amb_investment_breakdown_v`;

-- Also drop previous naming convention if running over an older deployment
DROP VIEW IF EXISTS `ai_ambitions.v_kpi_breakdown`;
DROP VIEW IF EXISTS `ai_ambitions.v_investment_breakdown`;


-- ── 2. Drop tables ────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS `ai_ambitions.ai_amb_use_case_metric`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_use_cases`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_dimension_metrics`;
DROP TABLE IF EXISTS `ai_ambitions.ai_amb_kpi_summary`;

-- Also drop previous naming convention
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
  actual_value  FLOAT64  NOT NULL OPTIONS(description='Raw metric value in display units (%, pts, or $M)'),
  plan_value    FLOAT64           OPTIONS(description='Planned / budget target in same units as actual_value'),
  actual_delta  FLOAT64           OPTIONS(description='Change vs comparison period; positive = improvement'),
  delta_label   STRING            OPTIONS(description='Human label for the delta, e.g. "vs Q3" or "vs plan"'),
  update_ts     TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_dimension_metrics
-- Single table for all category/vendor-level metrics across spend and KPIs.
-- Replaces the former ai_ambition_investment + ai_ambition_kpi_breakdown pair.
-- metric_id = 'cost'       → actual_value in $M   (investment spend)
-- metric_id = 'revenue'    → actual_value in %    (revenue growth contribution)
-- metric_id = 'nps'        → actual_value in pts  (NPS improvement contribution)
-- metric_id = 'efficiency' → actual_value in %    (efficiency gain contribution)
CREATE TABLE `ai_ambitions.ai_amb_dimension_metrics` (
  period          STRING   NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  metric_id       STRING   NOT NULL OPTIONS(description='cost | revenue | nps | efficiency'),
  dimension_type  STRING   NOT NULL OPTIONS(description='category | vendor'),
  dimension_name  STRING   NOT NULL OPTIONS(description='Human-readable label for this row'),
  actual_value    FLOAT64  NOT NULL OPTIONS(description='Metric value in units defined by metric_id'),
  plan_value      FLOAT64           OPTIONS(description='Planned value in same units as actual_value'),
  update_ts       TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_use_cases
-- Master list of AI use cases with metadata. Period-independent.
CREATE TABLE `ai_ambitions.ai_amb_use_cases` (
  use_case_name   STRING   NOT NULL OPTIONS(description='Unique use case identifier (display name)'),
  description     STRING            OPTIONS(description='One-sentence description shown on hover in the dashboard'),
  csg             STRING            OPTIONS(description='Consumer segment group / business unit'),
  functional_area STRING            OPTIONS(description='Primary function (e.g. Commerce, Supply Chain, CX)'),
  kpi_tag         STRING   NOT NULL OPTIONS(description='Primary KPI: REVENUE | NPS | EFFICIENCY'),
  display_rank    INT64             OPTIONS(description='Sort order in the use-case list (1 = highest spend)'),
  update_ts       TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);

-- Table: ai_amb_use_case_metric
-- All KPI metrics per use case per period in a single wide row.
-- Stores cost alongside all KPI metrics so each use case has one row per period.
CREATE TABLE `ai_ambitions.ai_amb_use_case_metric` (
  period             STRING   NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  use_case_name      STRING   NOT NULL OPTIONS(description='Foreign key to ai_amb_use_cases.use_case_name'),
  cost_actual        FLOAT64           OPTIONS(description='Actual AI spend attributed to this use case ($M)'),
  cost_plan          FLOAT64           OPTIONS(description='Planned spend ($M)'),
  revenue_actual     FLOAT64           OPTIONS(description='Revenue growth contribution (%)'),
  revenue_plan       FLOAT64           OPTIONS(description='Planned revenue growth contribution (%)'),
  nps_actual         FLOAT64           OPTIONS(description='NPS improvement contribution (pts)'),
  nps_plan           FLOAT64           OPTIONS(description='Planned NPS contribution (pts)'),
  efficiency_actual  FLOAT64           OPTIONS(description='Efficiency gain contribution (%)'),
  efficiency_plan    FLOAT64           OPTIONS(description='Planned efficiency contribution (%)'),
  update_ts          TIMESTAMP         OPTIONS(description='Last refresh timestamp')
);


-- ── 4. Create compatibility views ─────────────────────────────────────────────
--
-- These views expose the same column shape the backend already expects,
-- so no backend query changes are needed when the underlying tables evolve.

-- View: ai_amb_investment_breakdown_v
-- Combines cost rows from ai_amb_dimension_metrics with use-case rows
-- derived from ai_amb_use_cases JOIN ai_amb_use_case_metric.
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_investment_breakdown_v` AS
SELECT
  period,
  dimension_type,
  dimension_name,
  actual_value    AS actual_amount,
  plan_value      AS plan_amount,
  CAST(NULL AS STRING) AS kpi_tag,
  CAST(NULL AS INT64)  AS display_rank,
  CAST(NULL AS STRING) AS description,
  CAST(NULL AS STRING) AS csg,
  CAST(NULL AS STRING) AS functional_area
FROM `ai_ambitions.ai_amb_dimension_metrics`
WHERE metric_id = 'cost'

UNION ALL

SELECT
  ucm.period,
  'use_case'         AS dimension_type,
  uc.use_case_name   AS dimension_name,
  COALESCE(ucm.cost_actual, 0.0) AS actual_amount,
  ucm.cost_plan      AS plan_amount,
  uc.kpi_tag,
  uc.display_rank,
  uc.description,
  uc.csg,
  uc.functional_area
FROM `ai_ambitions.ai_amb_use_cases` uc
JOIN `ai_ambitions.ai_amb_use_case_metric` ucm
  ON uc.use_case_name = ucm.use_case_name;


-- View: ai_amb_kpi_breakdown_v
-- Combines revenue/nps/efficiency rows from ai_amb_dimension_metrics with
-- per-KPI use-case rows unpivoted from ai_amb_use_case_metric.
CREATE OR REPLACE VIEW `ai_ambitions.ai_amb_kpi_breakdown_v` AS
SELECT
  period,
  metric_id          AS kpi_id,
  dimension_type,
  dimension_name,
  actual_value,
  plan_value,
  CAST(NULL AS INT64) AS display_rank
FROM `ai_ambitions.ai_amb_dimension_metrics`
WHERE metric_id IN ('revenue', 'nps', 'efficiency')

UNION ALL

-- Revenue use-case rows (all use cases, ranked by their revenue contribution)
SELECT
  ucm.period,
  'revenue'          AS kpi_id,
  'use_case'         AS dimension_type,
  uc.use_case_name   AS dimension_name,
  COALESCE(ucm.revenue_actual, 0.0) AS actual_value,
  ucm.revenue_plan   AS plan_value,
  uc.display_rank
FROM `ai_ambitions.ai_amb_use_cases` uc
JOIN `ai_ambitions.ai_amb_use_case_metric` ucm
  ON uc.use_case_name = ucm.use_case_name

UNION ALL

-- NPS use-case rows (all use cases, ranked by their NPS contribution)
SELECT
  ucm.period,
  'nps'              AS kpi_id,
  'use_case'         AS dimension_type,
  uc.use_case_name   AS dimension_name,
  COALESCE(ucm.nps_actual, 0.0) AS actual_value,
  ucm.nps_plan       AS plan_value,
  uc.display_rank
FROM `ai_ambitions.ai_amb_use_cases` uc
JOIN `ai_ambitions.ai_amb_use_case_metric` ucm
  ON uc.use_case_name = ucm.use_case_name

UNION ALL

-- Efficiency use-case rows (all use cases, ranked by their efficiency contribution)
SELECT
  ucm.period,
  'efficiency'       AS kpi_id,
  'use_case'         AS dimension_type,
  uc.use_case_name   AS dimension_name,
  COALESCE(ucm.efficiency_actual, 0.0) AS actual_value,
  ucm.efficiency_plan AS plan_value,
  uc.display_rank
FROM `ai_ambitions.ai_amb_use_cases` uc
JOIN `ai_ambitions.ai_amb_use_case_metric` ucm
  ON uc.use_case_name = ucm.use_case_name;
