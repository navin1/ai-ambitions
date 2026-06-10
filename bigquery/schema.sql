-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — BigQuery Schema
-- Dataset: ai_ambitions  (create with: bq mk --dataset PROJECT:ai_ambitions)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Table 1: KPI Summary ──────────────────────────────────────────────────────
-- One row per (period, kpi_id).
-- The backend reads actual_value / plan_value and computes status + formatting.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `ai_ambitions.ai_ambition_kpi_summary` (
  period        STRING  NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  kpi_id        STRING  NOT NULL OPTIONS(description='revenue | nps | efficiency | ai-cost'),
  actual_value  FLOAT64 NOT NULL OPTIONS(description='Raw metric value (%, pts, or $M depending on kpi_id)'),
  plan_value    FLOAT64          OPTIONS(description='Planned / budget target in same unit as actual_value'),
  actual_delta  FLOAT64          OPTIONS(description='Change vs comparison period (positive = improvement)'),
  delta_label   STRING           OPTIONS(description='Human label for the delta, e.g. "vs Q3" or "vs plan"'),
  update_ts    TIMESTAMP        OPTIONS(description='Last refresh timestamp')
);

-- ── Table 2: Investment Breakdown ────────────────────────────────────────────
-- One row per (period, dimension_type, dimension_name).
-- dimension_type controls which drill-down view the row appears in.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `ai_ambitions.ai_ambition_investment` (
  period          STRING  NOT NULL OPTIONS(description='YTD | Q1 | Q2 | Q3 | Q4'),
  dimension_type  STRING  NOT NULL OPTIONS(description='category | use_case | vendor'),
  dimension_name  STRING  NOT NULL OPTIONS(description='Human-readable label for this row'),
  actual_amount   FLOAT64 NOT NULL OPTIONS(description='Actual spend in $M'),
  plan_amount     FLOAT64          OPTIONS(description='Planned spend in $M'),
  kpi_tag         STRING           OPTIONS(description='For use_case rows: REVENUE | NPS | EFFICIENCY'),
  display_rank    INT64            OPTIONS(description='For use_case rows: sort order (1-based)'),
  update_ts      TIMESTAMP        OPTIONS(description='Last refresh timestamp')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Seed data — mirrors the values previously hardcoded in AIAmbitionTab.tsx
-- Replace with your actual data when connecting to real sources.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── ai_ambition_kpi_summary seed ─────────────────────────────────────────────

INSERT INTO `ai_ambitions.ai_ambition_kpi_summary`
  (period, kpi_id, actual_value, plan_value, actual_delta, delta_label, update_ts)
VALUES
  -- YTD
  ('YTD', 'revenue',    4.6,  5.0,   0.4,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('YTD', 'nps',        2.7,  3.0,   0.3,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 27.0, 33.0,  5.0,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('YTD', 'ai-cost',   42.3, 45.0,  -2.7,  'vs plan', CURRENT_TIMESTAMP()),
  -- Q1
  ('Q1',  'revenue',    3.8,  4.0,   0.2,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'nps',        2.4,  2.5,   0.1,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 18.0, 25.0,  2.0,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'ai-cost',    9.8, 11.25, -1.5,  'vs plan',  CURRENT_TIMESTAMP()),
  -- Q2
  ('Q2',  'revenue',    5.1,  5.0,   1.3,  'vs Q1',   CURRENT_TIMESTAMP()),
  ('Q2',  'nps',        2.8,  3.0,   0.4,  'vs Q1',   CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 29.0, 32.0, 11.0,  'vs Q1',   CURRENT_TIMESTAMP()),
  ('Q2',  'ai-cost',   11.2, 11.25, -0.1,  'vs plan', CURRENT_TIMESTAMP()),
  -- Q3
  ('Q3',  'revenue',    4.9,  5.0,  -0.2,  'vs Q2',   CURRENT_TIMESTAMP()),
  ('Q3',  'nps',        2.9,  3.0,   0.1,  'vs Q2',   CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 31.0, 32.0,  2.0,  'vs Q2',   CURRENT_TIMESTAMP()),
  ('Q3',  'ai-cost',   13.8, 11.25,  2.6,  'vs plan', CURRENT_TIMESTAMP()),
  -- Q4
  ('Q4',  'revenue',    5.2,  5.0,   0.3,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('Q4',  'nps',        3.1,  3.0,   0.2,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 35.0, 35.0,  4.0,  'vs Q3',   CURRENT_TIMESTAMP()),
  ('Q4',  'ai-cost',    7.5, 11.25, -3.75, 'vs plan', CURRENT_TIMESTAMP());

-- ── ai_ambition_investment seed ───────────────────────────────────────────────

INSERT INTO `ai_ambitions.ai_ambition_investment`
  (period, dimension_type, dimension_name, actual_amount, plan_amount, kpi_tag, display_rank, update_ts)
VALUES
  -- YTD › category
  ('YTD', 'category', 'Foundation model inference', 18.2, 20.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'category', 'Cloud compute & storage',    11.4, 12.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'category', 'Data labeling & ops',         5.6,  6.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'category', 'Platform & MLOps tooling',    4.1,  4.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'category', 'Talent allocation',            3.0,  2.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  -- YTD › use_case
  ('YTD', 'use_case', 'Personalized Search & Discovery',  6.8, 7.5, 'REVENUE',    1, CURRENT_TIMESTAMP()),
  ('YTD', 'use_case', 'Demand Forecast v3',               4.8, 5.0, 'EFFICIENCY', 2, CURRENT_TIMESTAMP()),
  ('YTD', 'use_case', 'Dynamic Markdown Optimization',    4.2, 4.5, 'REVENUE',    3, CURRENT_TIMESTAMP()),
  ('YTD', 'use_case', 'Warehouse Slotting AI',            3.6, 4.0, 'EFFICIENCY', 4, CURRENT_TIMESTAMP()),
  ('YTD', 'use_case', 'Conversational Returns Assistant', 3.2, 3.5, 'NPS',        5, CURRENT_TIMESTAMP()),
  ('YTD', 'use_case', 'Chat Triage & Routing',            2.4, 2.5, 'NPS',        6, CURRENT_TIMESTAMP()),
  -- YTD › vendor
  ('YTD', 'vendor', 'Google Cloud (Vertex AI)', 14.1, 15.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'vendor', 'OpenAI / Azure OpenAI',    9.7, 10.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'vendor', 'AWS Bedrock',               7.5,  8.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'vendor', 'Scale AI (labeling)',        5.6,  6.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'vendor', 'Databricks',                3.2,  3.5, NULL, NULL, CURRENT_TIMESTAMP()),
  ('YTD', 'vendor', 'Other vendors',             2.2,  2.0, NULL, NULL, CURRENT_TIMESTAMP()),

  -- Q1 › category
  ('Q1', 'category', 'Foundation model inference', 4.2, 5.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'category', 'Cloud compute & storage',    2.5, 3.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'category', 'Data labeling & ops',         1.3, 1.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'category', 'Platform & MLOps tooling',    1.1, 1.1,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'category', 'Talent allocation',            0.7, 0.65, NULL, NULL, CURRENT_TIMESTAMP()),
  -- Q1 › use_case
  ('Q1', 'use_case', 'Personalized Search & Discovery',  1.5, 1.9, 'REVENUE',    1, CURRENT_TIMESTAMP()),
  ('Q1', 'use_case', 'Demand Forecast v3',               1.1, 1.2, 'EFFICIENCY', 2, CURRENT_TIMESTAMP()),
  ('Q1', 'use_case', 'Dynamic Markdown Optimization',    0.9, 1.1, 'REVENUE',    3, CURRENT_TIMESTAMP()),
  ('Q1', 'use_case', 'Warehouse Slotting AI',            0.8, 1.0, 'EFFICIENCY', 4, CURRENT_TIMESTAMP()),
  ('Q1', 'use_case', 'Conversational Returns Assistant', 0.7, 0.9, 'NPS',        5, CURRENT_TIMESTAMP()),
  -- Q1 › vendor
  ('Q1', 'vendor', 'Google Cloud (Vertex AI)', 3.2, 3.8, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'vendor', 'OpenAI / Azure OpenAI',    2.1, 2.6, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'vendor', 'AWS Bedrock',               1.8, 2.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'vendor', 'Scale AI (labeling)',        1.3, 1.5, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'vendor', 'Databricks',                0.8, 0.9, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q1', 'vendor', 'Other vendors',             0.6, 0.5, NULL, NULL, CURRENT_TIMESTAMP()),

  -- Q2 › category
  ('Q2', 'category', 'Foundation model inference', 4.9, 5.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'category', 'Cloud compute & storage',    2.8, 3.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'category', 'Data labeling & ops',         1.4, 1.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'category', 'Platform & MLOps tooling',    1.2, 1.1,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'category', 'Talent allocation',            0.9, 0.65, NULL, NULL, CURRENT_TIMESTAMP()),
  -- Q2 › use_case
  ('Q2', 'use_case', 'Personalized Search & Discovery',  1.8, 1.9, 'REVENUE',    1, CURRENT_TIMESTAMP()),
  ('Q2', 'use_case', 'Demand Forecast v3',               1.3, 1.2, 'EFFICIENCY', 2, CURRENT_TIMESTAMP()),
  ('Q2', 'use_case', 'Dynamic Markdown Optimization',    1.1, 1.1, 'REVENUE',    3, CURRENT_TIMESTAMP()),
  ('Q2', 'use_case', 'Warehouse Slotting AI',            1.0, 1.0, 'EFFICIENCY', 4, CURRENT_TIMESTAMP()),
  ('Q2', 'use_case', 'Conversational Returns Assistant', 0.9, 0.9, 'NPS',        5, CURRENT_TIMESTAMP()),
  ('Q2', 'use_case', 'Chat Triage & Routing',            0.7, 0.6, 'NPS',        6, CURRENT_TIMESTAMP()),
  -- Q2 › vendor
  ('Q2', 'vendor', 'Google Cloud (Vertex AI)', 3.7, 3.8, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'vendor', 'OpenAI / Azure OpenAI',    2.5, 2.6, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'vendor', 'AWS Bedrock',               2.1, 2.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'vendor', 'Scale AI (labeling)',        1.4, 1.5, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'vendor', 'Databricks',                0.9, 0.9, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q2', 'vendor', 'Other vendors',             0.6, 0.5, NULL, NULL, CURRENT_TIMESTAMP()),

  -- Q3 › category
  ('Q3', 'category', 'Foundation model inference', 5.9, 5.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'category', 'Cloud compute & storage',    3.5, 3.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'category', 'Data labeling & ops',         2.0, 1.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'category', 'Platform & MLOps tooling',    1.5, 1.1,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'category', 'Talent allocation',            0.9, 0.65, NULL, NULL, CURRENT_TIMESTAMP()),
  -- Q3 › use_case
  ('Q3', 'use_case', 'Personalized Search & Discovery',  2.2, 1.9, 'REVENUE',    1, CURRENT_TIMESTAMP()),
  ('Q3', 'use_case', 'Demand Forecast v3',               1.6, 1.2, 'EFFICIENCY', 2, CURRENT_TIMESTAMP()),
  ('Q3', 'use_case', 'Dynamic Markdown Optimization',    1.3, 1.1, 'REVENUE',    3, CURRENT_TIMESTAMP()),
  ('Q3', 'use_case', 'Warehouse Slotting AI',            1.1, 1.0, 'EFFICIENCY', 4, CURRENT_TIMESTAMP()),
  ('Q3', 'use_case', 'Conversational Returns Assistant', 1.0, 0.9, 'NPS',        5, CURRENT_TIMESTAMP()),
  ('Q3', 'use_case', 'Chat Triage & Routing',            0.8, 0.6, 'NPS',        6, CURRENT_TIMESTAMP()),
  -- Q3 › vendor
  ('Q3', 'vendor', 'Google Cloud (Vertex AI)', 4.5, 3.8, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'vendor', 'OpenAI / Azure OpenAI',    3.2, 2.6, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'vendor', 'AWS Bedrock',               2.4, 2.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'vendor', 'Scale AI (labeling)',        1.8, 1.5, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'vendor', 'Databricks',                1.1, 0.9, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q3', 'vendor', 'Other vendors',             0.8, 0.5, NULL, NULL, CURRENT_TIMESTAMP()),

  -- Q4 › category
  ('Q4', 'category', 'Foundation model inference', 3.2, 5.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'category', 'Cloud compute & storage',    1.9, 3.0,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'category', 'Data labeling & ops',         0.9, 1.5,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'category', 'Platform & MLOps tooling',    0.9, 1.1,  NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'category', 'Talent allocation',            0.6, 0.65, NULL, NULL, CURRENT_TIMESTAMP()),
  -- Q4 › use_case
  ('Q4', 'use_case', 'Personalized Search & Discovery',  1.3, 1.9, 'REVENUE',    1, CURRENT_TIMESTAMP()),
  ('Q4', 'use_case', 'Dynamic Markdown Optimization',    0.9, 1.1, 'REVENUE',    2, CURRENT_TIMESTAMP()),
  ('Q4', 'use_case', 'Demand Forecast v3',               0.8, 1.2, 'EFFICIENCY', 3, CURRENT_TIMESTAMP()),
  ('Q4', 'use_case', 'Warehouse Slotting AI',            0.7, 1.0, 'EFFICIENCY', 4, CURRENT_TIMESTAMP()),
  ('Q4', 'use_case', 'Conversational Returns Assistant', 0.6, 0.9, 'NPS',        5, CURRENT_TIMESTAMP()),
  -- Q4 › vendor
  ('Q4', 'vendor', 'Google Cloud (Vertex AI)', 2.5, 3.8, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'vendor', 'OpenAI / Azure OpenAI',    1.6, 2.6, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'vendor', 'AWS Bedrock',               1.3, 2.0, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'vendor', 'Scale AI (labeling)',        1.0, 1.5, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'vendor', 'Databricks',                0.6, 0.9, NULL, NULL, CURRENT_TIMESTAMP()),
  ('Q4', 'vendor', 'Other vendors',             0.5, 0.5, NULL, NULL, CURRENT_TIMESTAMP());
