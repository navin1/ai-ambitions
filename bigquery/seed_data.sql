-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — Seed Data
-- Run AFTER schema.sql.
--
-- Tables populated:
--   1. ai_amb_kpi_summary       (5 periods × 4 KPIs = 20 rows)
--   2. ai_amb_dimension_metrics (5 periods × 4 metric_ids × ~9 rows = ~180 rows)
--   3. ai_amb_use_cases         (6 use cases, period-independent)
--   4. ai_amb_use_case_metric   (6 use cases × 5 periods = 30 rows)
--
-- Use-case rows in the views are derived automatically from tables 3 + 4.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. ai_amb_kpi_summary ─────────────────────────────────────────────────────

INSERT INTO `ai_ambitions.ai_amb_kpi_summary`
  (period, kpi_id, actual_value, plan_value, actual_delta, delta_label, update_ts)
VALUES
  -- YTD
  ('YTD', 'revenue',    4.6,  5.0,   0.4,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('YTD', 'nps',        2.7,  3.0,   0.3,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 27.0, 33.0,  5.0,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('YTD', 'ai-cost',   42.3, 45.0,  -2.7,  'vs plan',  CURRENT_TIMESTAMP()),
  -- Q1
  ('Q1',  'revenue',    3.8,  4.0,   0.2,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'nps',        2.4,  2.5,   0.1,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 18.0, 25.0,  2.0,  "vs Q4'25", CURRENT_TIMESTAMP()),
  ('Q1',  'ai-cost',    9.8, 11.25, -1.5,  'vs plan',  CURRENT_TIMESTAMP()),
  -- Q2
  ('Q2',  'revenue',    5.1,  5.0,   1.3,  'vs Q1',    CURRENT_TIMESTAMP()),
  ('Q2',  'nps',        2.8,  3.0,   0.4,  'vs Q1',    CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 29.0, 32.0, 11.0,  'vs Q1',    CURRENT_TIMESTAMP()),
  ('Q2',  'ai-cost',   11.2, 11.25, -0.1,  'vs plan',  CURRENT_TIMESTAMP()),
  -- Q3
  ('Q3',  'revenue',    4.9,  5.0,  -0.2,  'vs Q2',    CURRENT_TIMESTAMP()),
  ('Q3',  'nps',        2.9,  3.0,   0.1,  'vs Q2',    CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 31.0, 32.0,  2.0,  'vs Q2',    CURRENT_TIMESTAMP()),
  ('Q3',  'ai-cost',   13.8, 11.25,  2.6,  'vs plan',  CURRENT_TIMESTAMP()),
  -- Q4
  ('Q4',  'revenue',    5.2,  5.0,   0.3,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('Q4',  'nps',        3.1,  3.0,   0.2,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 35.0, 35.0,  4.0,  'vs Q3',    CURRENT_TIMESTAMP()),
  ('Q4',  'ai-cost',    7.5, 11.25, -3.75, 'vs plan',  CURRENT_TIMESTAMP());


-- ── 2. ai_amb_dimension_metrics ───────────────────────────────────────────────
-- metric_id = 'cost'       → actual_value in $M
-- metric_id = 'revenue'    → actual_value in % growth contribution
-- metric_id = 'nps'        → actual_value in pts improvement contribution
-- metric_id = 'efficiency' → actual_value in % gain contribution

INSERT INTO `ai_ambitions.ai_amb_dimension_metrics`
  (period, metric_id, dimension_type, dimension_name, actual_value, plan_value, update_ts)
VALUES

  -- ═══════════════════════════════════════════════════════════════════════════
  -- metric_id = 'cost'  ($M spend by category / vendor)
  -- ═══════════════════════════════════════════════════════════════════════════

  -- YTD › cost › category
  ('YTD', 'cost', 'category', 'Foundation model inference', 18.2, 20.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Cloud compute & storage',    11.4, 12.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Data labeling & ops',         5.6,  6.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Platform & MLOps tooling',    4.1,  4.5,  CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Talent allocation',            3.0,  2.5,  CURRENT_TIMESTAMP()),
  -- YTD › cost › vendor
  ('YTD', 'cost', 'vendor', 'Google Cloud (Vertex AI)', 14.1, 15.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'OpenAI / Azure OpenAI',     9.7, 10.5, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'AWS Bedrock',               7.5,  8.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Scale AI (labeling)',        5.6,  6.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Databricks',                3.2,  3.5, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Other vendors',             2.2,  2.0, CURRENT_TIMESTAMP()),

  -- Q1 › cost › category
  ('Q1',  'cost', 'category', 'Foundation model inference', 4.2, 5.0,   CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'category', 'Cloud compute & storage',    2.5, 3.0,   CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'category', 'Data labeling & ops',         1.3, 1.5,   CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'category', 'Platform & MLOps tooling',    1.1, 1.1,   CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'category', 'Talent allocation',            0.7, 0.65,  CURRENT_TIMESTAMP()),
  -- Q1 › cost › vendor
  ('Q1',  'cost', 'vendor', 'Google Cloud (Vertex AI)', 3.2, 3.8, CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'vendor', 'OpenAI / Azure OpenAI',    2.1, 2.6, CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'vendor', 'AWS Bedrock',               1.8, 2.0, CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'vendor', 'Scale AI (labeling)',        1.3, 1.5, CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'vendor', 'Databricks',                0.8, 0.9, CURRENT_TIMESTAMP()),
  ('Q1',  'cost', 'vendor', 'Other vendors',             0.6, 0.5, CURRENT_TIMESTAMP()),

  -- Q2 › cost › category
  ('Q2',  'cost', 'category', 'Foundation model inference', 4.9, 5.0,   CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'category', 'Cloud compute & storage',    2.8, 3.0,   CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'category', 'Data labeling & ops',         1.4, 1.5,   CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'category', 'Platform & MLOps tooling',    1.2, 1.1,   CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'category', 'Talent allocation',            0.9, 0.65,  CURRENT_TIMESTAMP()),
  -- Q2 › cost › vendor
  ('Q2',  'cost', 'vendor', 'Google Cloud (Vertex AI)', 3.7, 3.8, CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'vendor', 'OpenAI / Azure OpenAI',    2.5, 2.6, CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'vendor', 'AWS Bedrock',               2.1, 2.0, CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'vendor', 'Scale AI (labeling)',        1.4, 1.5, CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'vendor', 'Databricks',                0.9, 0.9, CURRENT_TIMESTAMP()),
  ('Q2',  'cost', 'vendor', 'Other vendors',             0.6, 0.5, CURRENT_TIMESTAMP()),

  -- Q3 › cost › category
  ('Q3',  'cost', 'category', 'Foundation model inference', 5.9, 5.0,   CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'category', 'Cloud compute & storage',    3.5, 3.0,   CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'category', 'Data labeling & ops',         2.0, 1.5,   CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'category', 'Platform & MLOps tooling',    1.5, 1.1,   CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'category', 'Talent allocation',            0.9, 0.65,  CURRENT_TIMESTAMP()),
  -- Q3 › cost › vendor
  ('Q3',  'cost', 'vendor', 'Google Cloud (Vertex AI)', 4.5, 3.8, CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'vendor', 'OpenAI / Azure OpenAI',    3.2, 2.6, CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'vendor', 'AWS Bedrock',               2.4, 2.0, CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'vendor', 'Scale AI (labeling)',        1.8, 1.5, CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'vendor', 'Databricks',                1.1, 0.9, CURRENT_TIMESTAMP()),
  ('Q3',  'cost', 'vendor', 'Other vendors',             0.8, 0.5, CURRENT_TIMESTAMP()),

  -- Q4 › cost › category
  ('Q4',  'cost', 'category', 'Foundation model inference', 3.2, 5.0,   CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'category', 'Cloud compute & storage',    1.9, 3.0,   CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'category', 'Data labeling & ops',         0.9, 1.5,   CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'category', 'Platform & MLOps tooling',    0.9, 1.1,   CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'category', 'Talent allocation',            0.6, 0.65,  CURRENT_TIMESTAMP()),
  -- Q4 › cost › vendor
  ('Q4',  'cost', 'vendor', 'Google Cloud (Vertex AI)', 2.5, 3.8, CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'vendor', 'OpenAI / Azure OpenAI',    1.6, 2.6, CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'vendor', 'AWS Bedrock',               1.3, 2.0, CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'vendor', 'Scale AI (labeling)',        1.0, 1.5, CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'vendor', 'Databricks',                0.6, 0.9, CURRENT_TIMESTAMP()),
  ('Q4',  'cost', 'vendor', 'Other vendors',             0.5, 0.5, CURRENT_TIMESTAMP()),

  -- ═══════════════════════════════════════════════════════════════════════════
  -- metric_id = 'revenue'  (% growth contribution by category / vendor)
  -- ═══════════════════════════════════════════════════════════════════════════

  -- YTD › revenue › category
  ('YTD', 'revenue', 'category', 'Foundation model inference', 1.2, 1.5, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Cloud compute & storage',    0.8, 1.0, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Data labeling & ops',         0.5, 0.6, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Platform & MLOps tooling',    0.3, 0.4, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Talent allocation',            0.2, 0.3, CURRENT_TIMESTAMP()),
  -- YTD › revenue › vendor
  ('YTD', 'revenue', 'vendor', 'Google Cloud (Vertex AI)', 1.1, 1.3, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'OpenAI / Azure OpenAI',    0.9, 1.1, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'AWS Bedrock',               0.6, 0.8, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'Scale AI (labeling)',        0.2, 0.3, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'Databricks',                0.2, 0.2, CURRENT_TIMESTAMP()),

  -- Q1 › revenue › category
  ('Q1',  'revenue', 'category', 'Foundation model inference', 0.5, 0.6, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'category', 'Cloud compute & storage',    0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'category', 'Data labeling & ops',         0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'category', 'Platform & MLOps tooling',    0.1, 0.2, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q1 › revenue › vendor
  ('Q1',  'revenue', 'vendor', 'Google Cloud (Vertex AI)', 0.5, 0.6, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'vendor', 'OpenAI / Azure OpenAI',    0.4, 0.5, CURRENT_TIMESTAMP()),
  ('Q1',  'revenue', 'vendor', 'AWS Bedrock',               0.2, 0.3, CURRENT_TIMESTAMP()),

  -- Q2 › revenue › category
  ('Q2',  'revenue', 'category', 'Foundation model inference', 0.7, 0.7, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'category', 'Cloud compute & storage',    0.4, 0.4, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'category', 'Data labeling & ops',         0.3, 0.3, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'category', 'Platform & MLOps tooling',    0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q2 › revenue › vendor
  ('Q2',  'revenue', 'vendor', 'Google Cloud (Vertex AI)', 0.6, 0.6, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'vendor', 'OpenAI / Azure OpenAI',    0.5, 0.5, CURRENT_TIMESTAMP()),
  ('Q2',  'revenue', 'vendor', 'AWS Bedrock',               0.3, 0.3, CURRENT_TIMESTAMP()),

  -- Q3 › revenue › category
  ('Q3',  'revenue', 'category', 'Foundation model inference', 0.8, 0.7, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'category', 'Cloud compute & storage',    0.5, 0.4, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'category', 'Data labeling & ops',         0.3, 0.3, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'category', 'Platform & MLOps tooling',    0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q3 › revenue › vendor
  ('Q3',  'revenue', 'vendor', 'Google Cloud (Vertex AI)', 0.7, 0.6, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'vendor', 'OpenAI / Azure OpenAI',    0.5, 0.5, CURRENT_TIMESTAMP()),
  ('Q3',  'revenue', 'vendor', 'AWS Bedrock',               0.4, 0.3, CURRENT_TIMESTAMP()),

  -- Q4 › revenue › category
  ('Q4',  'revenue', 'category', 'Foundation model inference', 0.5, 0.7, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'category', 'Cloud compute & storage',    0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'category', 'Data labeling & ops',         0.2, 0.3, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'category', 'Platform & MLOps tooling',    0.1, 0.2, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q4 › revenue › vendor
  ('Q4',  'revenue', 'vendor', 'Google Cloud (Vertex AI)', 0.4, 0.6, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'vendor', 'OpenAI / Azure OpenAI',    0.3, 0.5, CURRENT_TIMESTAMP()),
  ('Q4',  'revenue', 'vendor', 'AWS Bedrock',               0.2, 0.3, CURRENT_TIMESTAMP()),

  -- ═══════════════════════════════════════════════════════════════════════════
  -- metric_id = 'nps'  (pts improvement contribution by category / vendor)
  -- ═══════════════════════════════════════════════════════════════════════════

  -- YTD › nps › category
  ('YTD', 'nps', 'category', 'Foundation model inference', 0.9, 1.0, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Cloud compute & storage',    0.5, 0.6, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Data labeling & ops',         0.4, 0.5, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Platform & MLOps tooling',    0.2, 0.3, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Talent allocation',            0.2, 0.2, CURRENT_TIMESTAMP()),
  -- YTD › nps › vendor
  ('YTD', 'nps', 'vendor', 'Google Cloud (Vertex AI)', 0.8, 1.0, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'OpenAI / Azure OpenAI',    0.6, 0.7, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'AWS Bedrock',               0.5, 0.6, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'Scale AI (labeling)',        0.3, 0.3, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'Databricks',                0.2, 0.2, CURRENT_TIMESTAMP()),

  -- Q1 › nps › category
  ('Q1',  'nps', 'category', 'Foundation model inference', 0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'category', 'Cloud compute & storage',    0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'category', 'Data labeling & ops',         0.1, 0.2, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'category', 'Platform & MLOps tooling',    0.1, 0.1, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q1 › nps › vendor
  ('Q1',  'nps', 'vendor', 'Google Cloud (Vertex AI)', 0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'vendor', 'OpenAI / Azure OpenAI',    0.2, 0.3, CURRENT_TIMESTAMP()),
  ('Q1',  'nps', 'vendor', 'AWS Bedrock',               0.2, 0.2, CURRENT_TIMESTAMP()),

  -- Q2 › nps › category
  ('Q2',  'nps', 'category', 'Foundation model inference', 0.4, 0.4, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'category', 'Cloud compute & storage',    0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'category', 'Data labeling & ops',         0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'category', 'Platform & MLOps tooling',    0.1, 0.1, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q2 › nps › vendor
  ('Q2',  'nps', 'vendor', 'Google Cloud (Vertex AI)', 0.4, 0.4, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'vendor', 'OpenAI / Azure OpenAI',    0.3, 0.3, CURRENT_TIMESTAMP()),
  ('Q2',  'nps', 'vendor', 'AWS Bedrock',               0.2, 0.2, CURRENT_TIMESTAMP()),

  -- Q3 › nps › category
  ('Q3',  'nps', 'category', 'Foundation model inference', 0.5, 0.4, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'category', 'Cloud compute & storage',    0.3, 0.3, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'category', 'Data labeling & ops',         0.2, 0.2, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'category', 'Platform & MLOps tooling',    0.1, 0.1, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q3 › nps › vendor
  ('Q3',  'nps', 'vendor', 'Google Cloud (Vertex AI)', 0.5, 0.4, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'vendor', 'OpenAI / Azure OpenAI',    0.3, 0.3, CURRENT_TIMESTAMP()),
  ('Q3',  'nps', 'vendor', 'AWS Bedrock',               0.3, 0.3, CURRENT_TIMESTAMP()),

  -- Q4 › nps › category
  ('Q4',  'nps', 'category', 'Foundation model inference', 0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'category', 'Cloud compute & storage',    0.2, 0.3, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'category', 'Data labeling & ops',         0.1, 0.2, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'category', 'Platform & MLOps tooling',    0.1, 0.1, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'category', 'Talent allocation',            0.1, 0.1, CURRENT_TIMESTAMP()),
  -- Q4 › nps › vendor
  ('Q4',  'nps', 'vendor', 'Google Cloud (Vertex AI)', 0.3, 0.4, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'vendor', 'OpenAI / Azure OpenAI',    0.2, 0.3, CURRENT_TIMESTAMP()),
  ('Q4',  'nps', 'vendor', 'AWS Bedrock',               0.1, 0.2, CURRENT_TIMESTAMP()),

  -- ═══════════════════════════════════════════════════════════════════════════
  -- metric_id = 'efficiency'  (% gain contribution by category / vendor)
  -- ═══════════════════════════════════════════════════════════════════════════

  -- YTD › efficiency › category
  ('YTD', 'efficiency', 'category', 'Foundation model inference', 6.0, 7.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Cloud compute & storage',    3.5, 4.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Data labeling & ops',         2.5, 3.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Platform & MLOps tooling',    1.7, 2.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Talent allocation',            1.0, 1.5, CURRENT_TIMESTAMP()),
  -- YTD › efficiency › vendor
  ('YTD', 'efficiency', 'vendor', 'Google Cloud (Vertex AI)', 5.5, 6.5, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'OpenAI / Azure OpenAI',    3.8, 4.5, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'AWS Bedrock',               3.2, 4.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'Databricks',                2.2, 3.0, CURRENT_TIMESTAMP()),

  -- Q1 › efficiency › category
  ('Q1',  'efficiency', 'category', 'Foundation model inference', 2.5, 3.0, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'category', 'Cloud compute & storage',    1.5, 1.8, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'category', 'Data labeling & ops',         1.0, 1.2, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'category', 'Platform & MLOps tooling',    0.7, 0.8, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'category', 'Talent allocation',            0.3, 0.5, CURRENT_TIMESTAMP()),
  -- Q1 › efficiency › vendor
  ('Q1',  'efficiency', 'vendor', 'Google Cloud (Vertex AI)', 2.2, 2.5, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'vendor', 'OpenAI / Azure OpenAI',    1.5, 1.8, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'vendor', 'AWS Bedrock',               1.2, 1.5, CURRENT_TIMESTAMP()),
  ('Q1',  'efficiency', 'vendor', 'Databricks',                0.8, 1.0, CURRENT_TIMESTAMP()),

  -- Q2 › efficiency › category
  ('Q2',  'efficiency', 'category', 'Foundation model inference', 3.2, 3.5, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'category', 'Cloud compute & storage',    2.0, 2.2, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'category', 'Data labeling & ops',         1.5, 1.5, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'category', 'Platform & MLOps tooling',    1.0, 1.0, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'category', 'Talent allocation',            0.5, 0.6, CURRENT_TIMESTAMP()),
  -- Q2 › efficiency › vendor
  ('Q2',  'efficiency', 'vendor', 'Google Cloud (Vertex AI)', 3.0, 3.2, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'vendor', 'OpenAI / Azure OpenAI',    2.2, 2.5, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'vendor', 'AWS Bedrock',               1.8, 2.0, CURRENT_TIMESTAMP()),
  ('Q2',  'efficiency', 'vendor', 'Databricks',                1.2, 1.5, CURRENT_TIMESTAMP()),

  -- Q3 › efficiency › category
  ('Q3',  'efficiency', 'category', 'Foundation model inference', 4.0, 3.5, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'category', 'Cloud compute & storage',    2.5, 2.2, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'category', 'Data labeling & ops',         1.8, 1.5, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'category', 'Platform & MLOps tooling',    1.2, 1.0, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'category', 'Talent allocation',            0.6, 0.5, CURRENT_TIMESTAMP()),
  -- Q3 › efficiency › vendor
  ('Q3',  'efficiency', 'vendor', 'Google Cloud (Vertex AI)', 3.8, 3.5, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'vendor', 'OpenAI / Azure OpenAI',    2.8, 2.5, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'vendor', 'AWS Bedrock',               2.2, 2.0, CURRENT_TIMESTAMP()),
  ('Q3',  'efficiency', 'vendor', 'Databricks',                1.5, 1.2, CURRENT_TIMESTAMP()),

  -- Q4 › efficiency › category
  ('Q4',  'efficiency', 'category', 'Foundation model inference', 2.2, 3.5, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'category', 'Cloud compute & storage',    1.4, 2.2, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'category', 'Data labeling & ops',         1.0, 1.5, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'category', 'Platform & MLOps tooling',    0.7, 1.0, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'category', 'Talent allocation',            0.3, 0.5, CURRENT_TIMESTAMP()),
  -- Q4 › efficiency › vendor
  ('Q4',  'efficiency', 'vendor', 'Google Cloud (Vertex AI)', 2.0, 3.2, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'vendor', 'OpenAI / Azure OpenAI',    1.5, 2.5, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'vendor', 'AWS Bedrock',               1.0, 2.0, CURRENT_TIMESTAMP()),
  ('Q4',  'efficiency', 'vendor', 'Databricks',                0.6, 1.2, CURRENT_TIMESTAMP());


-- ── 3. ai_amb_use_cases (master, period-independent) ─────────────────────────

INSERT INTO `ai_ambitions.ai_amb_use_cases`
  (use_case_name, description, csg, functional_area, kpi_tag, display_rank, update_ts)
VALUES
  (
    'Personalized Search & Discovery',
    'AI-driven product discovery that personalizes search results using behavioral signals and real-time context to lift conversion.',
    'Retail', 'Commerce', 'REVENUE', 1, CURRENT_TIMESTAMP()
  ),
  (
    'Demand Forecast v3',
    'ML-based multi-variate demand forecasting model that reduces overstock and understock costs by improving inventory accuracy.',
    'Supply Chain', 'Operations', 'EFFICIENCY', 2, CURRENT_TIMESTAMP()
  ),
  (
    'Dynamic Markdown Optimization',
    'Real-time AI markdown recommendations that maximize margin recovery on aged inventory while meeting clearance targets.',
    'Merchandising', 'Finance', 'REVENUE', 3, CURRENT_TIMESTAMP()
  ),
  (
    'Warehouse Slotting AI',
    'AI-powered slotting that minimizes pick-path distances and improves fulfillment throughput without physical reconfiguration.',
    'Supply Chain', 'Operations', 'EFFICIENCY', 4, CURRENT_TIMESTAMP()
  ),
  (
    'Conversational Returns Assistant',
    'LLM-powered virtual agent handling returns, exchanges, and refunds end-to-end, reducing live-agent contact volume.',
    'Customer Service', 'CX', 'NPS', 5, CURRENT_TIMESTAMP()
  ),
  (
    'Chat Triage & Routing',
    'Intelligent classification and routing of inbound chats to the right agent or self-serve path, cutting average handle time.',
    'Customer Service', 'CX', 'NPS', 6, CURRENT_TIMESTAMP()
  ),
  ('AI-Assisted Content Creation', 'Generative AI to create marketing copy, product descriptions, and blog posts, increasing content velocity.', 'Marketing', 'Marketing', 'EFFICIENCY', 7, CURRENT_TIMESTAMP()),
  ('Supply Chain Anomaly Detection', 'ML models to detect and flag anomalies in supply chain operations, preventing costly disruptions.', 'Supply Chain', 'Operations', 'EFFICIENCY', 8, CURRENT_TIMESTAMP()),
  ('Customer Churn Prediction', 'Predictive model to identify customers at high risk of churning, enabling proactive retention campaigns.', 'Marketing', 'CX', 'REVENUE', 9, CURRENT_TIMESTAMP()),
  ('Visual Search for Products', 'Allow users to search for products using images, improving discovery for visually-driven categories.', 'Retail', 'Commerce', 'REVENUE', 10, CURRENT_TIMESTAMP()),
  ('Automated Document Processing', 'OCR and NLP to extract structured data from invoices, receipts, and contracts, reducing manual data entry.', 'Finance', 'Operations', 'EFFICIENCY', 11, CURRENT_TIMESTAMP()),
  ('HR Candidate Screening', 'AI to screen and rank job applicants based on resume data against job requirements, speeding up recruitment.', 'Human Resources', 'HR', 'EFFICIENCY', 12, CURRENT_TIMESTAMP()),
  ('Sentiment Analysis on Reviews', 'Analyze customer sentiment in product reviews and support tickets to identify product quality issues.', 'Product', 'CX', 'NPS', 13, CURRENT_TIMESTAMP()),
  ('Fraud Detection Engine', 'Real-time transaction monitoring to detect and block fraudulent activities, reducing financial losses.', 'Security', 'Finance', 'EFFICIENCY', 14, CURRENT_TIMESTAMP()),
  ('Personalized Email Campaigns', 'Use customer data to personalize email marketing content and send times, boosting engagement.', 'Marketing', 'Marketing', 'REVENUE', 15, CURRENT_TIMESTAMP()),
  ('IT Helpdesk Ticket Automation', 'LLM-based agent to resolve common IT support requests automatically, freeing up helpdesk staff.', 'IT', 'Operations', 'EFFICIENCY', 16, CURRENT_TIMESTAMP()),
  ('Store Layout Optimization', 'Analyze in-store traffic patterns to optimize product placement and store layout for increased sales.', 'Retail', 'Operations', 'REVENUE', 17, CURRENT_TIMESTAMP()),
  ('Voice of the Customer Analytics', 'Aggregate and analyze customer feedback from all channels to derive actionable product insights.', 'Product', 'CX', 'NPS', 18, CURRENT_TIMESTAMP()),
  ('Energy Consumption Forecasting', 'Predict energy usage in warehouses and stores to optimize procurement and reduce utility costs.', 'Facilities', 'Operations', 'EFFICIENCY', 19, CURRENT_TIMESTAMP()),
  ('Marketing Mix Modeling', 'Attribute marketing spend to sales outcomes to optimize budget allocation across channels.', 'Marketing', 'Marketing', 'REVENUE', 20, CURRENT_TIMESTAMP()),
  ('Code Co-pilot & Review Assistant', 'Developer productivity tools for code generation, completion, and automated pull request reviews.', 'Engineering', 'Technology', 'EFFICIENCY', 21, CURRENT_TIMESTAMP()),
  ('Contact Center Quality Assurance', 'AI to automatically monitor and score agent interactions against quality and compliance rubrics.', 'Customer Service', 'CX', 'NPS', 22, CURRENT_TIMESTAMP()),
  ('Dynamic Pricing Engine', 'Adjust product prices in real-time based on demand, competition, and inventory levels to maximize revenue.', 'Merchandising', 'Commerce', 'REVENUE', 23, CURRENT_TIMESTAMP()),
  ('Logistics Route Optimization', 'Optimize delivery routes for last-mile fleet to reduce fuel costs and improve delivery times.', 'Supply Chain', 'Operations', 'EFFICIENCY', 24, CURRENT_TIMESTAMP()),
  ('Product Recommendation API', 'Provide personalized product recommendations on product detail pages to increase average order value.', 'Retail', 'Commerce', 'REVENUE', 25, CURRENT_TIMESTAMP()),
  ('Employee Retention Risk Model', 'Predict employee attrition risk to allow for targeted interventions by managers and HR.', 'Human Resources', 'HR', 'EFFICIENCY', 26, CURRENT_TIMESTAMP()),
  ('Automated Knowledge Base Writer', 'Generative AI to draft and update internal and external knowledge base articles from support tickets.', 'Customer Service', 'CX', 'NPS', 27, CURRENT_TIMESTAMP()),
  ('A/B Test Analysis Automation', 'Automatically analyze results of A/B tests and provide statistical summaries and recommendations.', 'Product', 'Marketing', 'EFFICIENCY', 28, CURRENT_TIMESTAMP()),
  ('Social Media Trend Identification', 'Monitor social media channels to identify emerging trends and brand mentions in real-time.', 'Marketing', 'Marketing', 'REVENUE', 29, CURRENT_TIMESTAMP()),
  ('Procurement Spend Analytics', 'Analyze procurement data to identify cost-saving opportunities and improve vendor negotiations.', 'Finance', 'Operations', 'EFFICIENCY', 30, CURRENT_TIMESTAMP()),
  ('Website Personalization Engine', 'Dynamically alter website content and layout for individual users to improve engagement.', 'Retail', 'Commerce', 'REVENUE', 31, CURRENT_TIMESTAMP()),
  ('Predictive Maintenance for Fleet', 'Forecast vehicle maintenance needs to prevent breakdowns and optimize service schedules.', 'Supply Chain', 'Operations', 'EFFICIENCY', 32, CURRENT_TIMESTAMP()),
  ('Customer Service Bot Escalation', 'Intelligently decide when to escalate a customer from a bot to a human agent to improve satisfaction.', 'Customer Service', 'CX', 'NPS', 33, CURRENT_TIMESTAMP()),
  ('Financial Anomaly Detection', 'Scan financial records for anomalies that could indicate fraud, error, or non-compliance.', 'Finance', 'Finance', 'EFFICIENCY', 34, CURRENT_TIMESTAMP()),
  ('Ad Creative Generation', 'Use generative AI to create variations of ad images and copy for performance marketing campaigns.', 'Marketing', 'Marketing', 'REVENUE', 35, CURRENT_TIMESTAMP()),
  ('Internal Document Search', 'LLM-powered search across internal documents, wikis, and shared drives.', 'IT', 'Operations', 'EFFICIENCY', 36, CURRENT_TIMESTAMP()),
  ('Customer Lifetime Value (CLV) Prediction', 'Forecast the total revenue a business can expect from a single customer account.', 'Marketing', 'Finance', 'REVENUE', 37, CURRENT_TIMESTAMP()),
  ('Automated Video Content Tagging', 'AI to automatically tag video content with relevant keywords, improving searchability and discovery.', 'Marketing', 'Media', 'EFFICIENCY', 38, CURRENT_TIMESTAMP()),
  ('On-Call Incident Triage', 'Triage and route production engineering alerts to the correct on-call engineer.', 'Engineering', 'Technology', 'EFFICIENCY', 39, CURRENT_TIMESTAMP()),
  ('Personalized In-App Notifications', 'Tailor push notifications and in-app messages based on user behavior to drive specific actions.', 'Product', 'Marketing', 'REVENUE', 40, CURRENT_TIMESTAMP()),
  ('Legal Contract Review AI', 'AI to review legal contracts for standard clauses, risks, and deviations from templates.', 'Legal', 'Operations', 'EFFICIENCY', 41, CURRENT_TIMESTAMP()),
  ('Competitor Price Monitoring', 'Automatically track competitor pricing and promotions to inform pricing strategy.', 'Merchandising', 'Commerce', 'REVENUE', 42, CURRENT_TIMESTAMP()),
  ('Call Center Transcription & Analysis', 'Transcribe and analyze all call center conversations to identify trends and agent performance issues.', 'Customer Service', 'CX', 'NPS', 43, CURRENT_TIMESTAMP()),
  ('Cloud Cost Optimization AI', 'Analyze cloud usage patterns and recommend cost-saving actions like rightsizing and spot instance usage.', 'Engineering', 'Technology', 'EFFICIENCY', 44, CURRENT_TIMESTAMP()),
  ('Product Information Management (PIM) AI', 'Use AI to enrich and standardize product attributes and descriptions in the PIM system.', 'Retail', 'Operations', 'EFFICIENCY', 45, CURRENT_TIMESTAMP()),
  ('Market Basket Analysis', 'Identify products that are frequently purchased together to inform cross-selling and product placement.', 'Retail', 'Commerce', 'REVENUE', 46, CURRENT_TIMESTAMP()),
  ('Employee Survey Analysis', 'NLP to analyze open-ended text from employee engagement surveys to identify key themes.', 'Human Resources', 'HR', 'NPS', 47, CURRENT_TIMESTAMP()),
  ('IT Asset Management AI', 'Predictive models to forecast IT hardware lifecycle and replacement needs.', 'IT', 'Operations', 'EFFICIENCY', 48, CURRENT_TIMESTAMP()),
  ('Next Best Action for Sales', 'Recommend the next best action for sales reps to take with a given customer to advance a deal.', 'Sales', 'Commerce', 'REVENUE', 49, CURRENT_TIMESTAMP()),
  ('Accessibility Issue Detection', 'Automated scanning of web frontends to detect and report accessibility (a11y) issues.', 'Engineering', 'Technology', 'NPS', 50, CURRENT_TIMESTAMP()),
  ('Digital Twin for Store Operations', 'Create a virtual replica of a physical store to simulate and optimize operations.', 'Retail', 'Operations', 'EFFICIENCY', 51, CURRENT_TIMESTAMP()),
  ('AI-Powered Merchandising Allocation', 'Optimize inventory allocation to stores based on localized demand signals.', 'Merchandising', 'Commerce', 'REVENUE', 52, CURRENT_TIMESTAMP()),
  ('Customer Journey Orchestration', 'Use AI to guide customers through personalized cross-channel journeys.', 'Marketing', 'CX', 'NPS', 53, CURRENT_TIMESTAMP()),
  ('Automated Code Documentation', 'Generative AI to automatically write and maintain documentation for source code.', 'Engineering', 'Technology', 'EFFICIENCY', 54, CURRENT_TIMESTAMP()),
  ('Marketing Campaign Lookalike Modeling', 'Identify and target new audiences that resemble existing high-value customers.', 'Marketing', 'Marketing', 'REVENUE', 55, CURRENT_TIMESTAMP()),
  ('Resume Parsing and Structuring', 'Extract structured information from resumes of all formats into a standardized schema.', 'Human Resources', 'HR', 'EFFICIENCY', 56, CURRENT_TIMESTAMP()),
  ('Product Defect Detection (Visual)', 'Use computer vision to automatically detect manufacturing defects on production lines.', 'Supply Chain', 'Operations', 'EFFICIENCY', 57, CURRENT_TIMESTAMP()),
  ('Subscription Propensity Modeling', 'Predict which customers are most likely to subscribe to a new service or product.', 'Marketing', 'REVENUE', 58, CURRENT_TIMESTAMP()),
  ('Email Threat Detection', 'Advanced ML models to detect phishing, malware, and BEC attacks in corporate email.', 'Security', 'IT', 'EFFICIENCY', 59, CURRENT_TIMESTAMP()),
  ('Intelligent Document Redaction', 'Automatically identify and redact PII and sensitive data from documents.', 'Legal', 'Operations', 'EFFICIENCY', 60, CURRENT_TIMESTAMP()),
  ('Personalized Financial Advice Bot', 'A chatbot providing personalized financial advice and planning for customers.', 'Finance', 'CX', 'NPS', 61, CURRENT_TIMESTAMP()),
  ('Network Intrusion Detection System', 'AI-based monitoring of network traffic to detect and alert on anomalous patterns.', 'Security', 'Technology', 'EFFICIENCY', 62, CURRENT_TIMESTAMP()),
  ('AI-Generated Training Content', 'Create personalized training modules and materials for employees based on their role and skill gaps.', 'Human Resources', 'HR', 'EFFICIENCY', 63, CURRENT_TIMESTAMP()),
  ('Customer Sentiment Driven Routing', 'Route frustrated or high-value customers to specialized support queues based on real-time sentiment.', 'Customer Service', 'CX', 'NPS', 64, CURRENT_TIMESTAMP()),
  ('Lead Scoring Model', 'Rank inbound sales leads based on their likelihood to convert, prioritizing sales team efforts.', 'Sales', 'Commerce', 'REVENUE', 65, CURRENT_TIMESTAMP()),
  ('Automated Data Quality Monitoring', 'AI models that continuously monitor data pipelines for anomalies and quality degradation.', 'Engineering', 'Technology', 'EFFICIENCY', 66, CURRENT_TIMESTAMP()),
  ('Real-time Language Translation for Support', 'Provide real-time translation for chat and email support for global customers.', 'Customer Service', 'CX', 'NPS', 67, CURRENT_TIMESTAMP()),
  ('Inventory Shrinkage Prediction', 'Predict and identify stores or product categories at high risk of inventory shrinkage (theft/loss).', 'Retail', 'Operations', 'EFFICIENCY', 68, CURRENT_TIMESTAMP()),
  ('Dynamic Ad Targeting', 'Optimize digital ad spend by dynamically targeting audiences most likely to engage.', 'Marketing', 'Marketing', 'REVENUE', 69, CURRENT_TIMESTAMP()),
  ('AI-Assisted Diagnosis (Internal Tools)', 'Internal tools for technical support teams to diagnose product issues faster.', 'Engineering', 'Technology', 'EFFICIENCY', 70, CURRENT_TIMESTAMP()),
  ('Automated ESG Reporting', 'AI to collect, analyze, and report on data for Environmental, Social, and Governance disclosures.', 'Finance', 'Legal', 'EFFICIENCY', 71, CURRENT_TIMESTAMP()),
  ('Customer Feedback Topic Modeling', 'Unsupervised learning to discover and track topics in customer feedback over time.', 'Product', 'CX', 'NPS', 72, CURRENT_TIMESTAMP()),
  ('Personalized Content Feed', 'Algorithmically curate a personalized feed of articles, videos, and products for users.', 'Retail', 'Commerce', 'REVENUE', 73, CURRENT_TIMESTAMP()),
  ('IT Service Management (ITSM) Automation', 'Automate incident creation, categorization, and routing in ITSM platforms.', 'IT', 'Operations', 'EFFICIENCY', 74, CURRENT_TIMESTAMP()),
  ('Employee Skill Gap Analysis', 'Analyze employee data to identify current and future skill gaps within the organization.', 'Human Resources', 'HR', 'EFFICIENCY', 75, CURRENT_TIMESTAMP()),
  ('AI-Powered Contract Lifecycle Management', 'Manage contracts from creation to renewal with AI-driven insights and alerts.', 'Legal', 'Operations', 'EFFICIENCY', 76, CURRENT_TIMESTAMP()),
  ('Predictive Cash Flow Forecasting', 'Use ML to provide more accurate and timely cash flow predictions for the finance department.', 'Finance', 'Finance', 'EFFICIENCY', 77, CURRENT_TIMESTAMP()),
  ('Social Media Content Moderation', 'Automatically detect and remove harmful or inappropriate content from user-generated posts.', 'Marketing', 'CX', 'NPS', 78, CURRENT_TIMESTAMP()),
  ('Upsell/Cross-sell Recommendation Engine', 'Recommend relevant add-on products or services during the checkout process.', 'Retail', 'Commerce', 'REVENUE', 79, CURRENT_TIMESTAMP()),
  ('Automated Threat Intelligence Analysis', 'AI to analyze and prioritize threat intelligence feeds for the security team.', 'Security', 'Technology', 'EFFICIENCY', 80, CURRENT_TIMESTAMP()),
  ('Voice-based In-store Assistant', 'Voice-activated assistants in stores to help customers find products or get information.', 'Retail', 'CX', 'NPS', 81, CURRENT_TIMESTAMP()),
  ('AI for Site Reliability Engineering (SRE)', 'Predictive models to anticipate system failures and performance bottlenecks.', 'Engineering', 'Technology', 'EFFICIENCY', 82, CURRENT_TIMESTAMP()),
  ('Personalized Marketing Offer Generation', 'Generate unique promotional offers for individual customers based on their profile.', 'Marketing', 'Marketing', 'REVENUE', 83, CURRENT_TIMESTAMP()),
  ('Automated Interview Scheduling', 'AI assistant to coordinate and schedule interviews between candidates and hiring managers.', 'Human Resources', 'HR', 'EFFICIENCY', 84, CURRENT_TIMESTAMP()),
  ('Customer Identity Verification', 'Use biometrics and AI to securely verify customer identities during onboarding.', 'Security', 'CX', 'NPS', 85, CURRENT_TIMESTAMP()),
  ('AI-Assisted Sales Forecasting', 'ML models to predict sales outcomes with higher accuracy, improving planning.', 'Sales', 'Finance', 'REVENUE', 86, CURRENT_TIMESTAMP()),
  ('Automated Invoice Reconciliation', 'Match and reconcile invoices against purchase orders and receipts automatically.', 'Finance', 'Operations', 'EFFICIENCY', 87, CURRENT_TIMESTAMP()),
  ('In-Game Player Behavior Analysis', 'Analyze player behavior in online games to detect cheating or toxic interactions.', 'Gaming', 'CX', 'NPS', 88, CURRENT_TIMESTAMP()),
  ('Dynamic Resource Allocation in Cloud', 'Automatically scale cloud resources up or down based on real-time workload.', 'Engineering', 'Technology', 'EFFICIENCY', 89, CURRENT_TIMESTAMP()),
  ('AI-Powered Event Correlation for IT Ops', 'Reduce alert noise by correlating disparate IT events into single actionable incidents.', 'IT', 'Operations', 'EFFICIENCY', 90, CURRENT_TIMESTAMP()),
  ('Personalized Loyalty Program Rewards', 'Tailor loyalty program rewards and incentives to individual customer preferences.', 'Marketing', 'CX', 'NPS', 91, CURRENT_TIMESTAMP()),
  ('Automated Ad Copy Performance Testing', 'Continuously test and iterate on ad copy using generative AI and performance data.', 'Marketing', 'Marketing', 'REVENUE', 92, CURRENT_TIMESTAMP()),
  ('Smart Building Energy Management', 'Optimize HVAC and lighting in corporate buildings based on occupancy and weather.', 'Facilities', 'Operations', 'EFFICIENCY', 93, CURRENT_TIMESTAMP()),
  ('AI-based Clinical Trial Patient Matching', 'Match patients to relevant clinical trials based on their medical history and profile.', 'Healthcare', 'R&D', 'EFFICIENCY', 94, CURRENT_TIMESTAMP()),
  ('Automated Financial Statement Analysis', 'Use NLP to extract key metrics and insights from financial statements and reports.', 'Finance', 'Finance', 'EFFICIENCY', 95, CURRENT_TIMESTAMP()),
  ('Customer Service Agent Assist', 'Provide real-time suggestions and knowledge base articles to support agents during calls.', 'Customer Service', 'CX', 'NPS', 96, CURRENT_TIMESTAMP()),
  ('AI-driven Game Asset Generation', 'Use generative AI to create textures, models, and other assets for game development.', 'Gaming', 'Technology', 'EFFICIENCY', 97, CURRENT_TIMESTAMP()),
  ('Personalized Nutrition and Wellness Plans', 'Generate personalized health plans for customers based on their goals and biometrics.', 'Healthcare', 'CX', 'NPS', 98, CURRENT_TIMESTAMP())
  ),
  ('AI-Assisted Content Creation', 'Generative AI to create marketing copy, product descriptions, and blog posts, increasing content velocity.', 'Marketing', 'Marketing', 'EFFICIENCY', 7, CURRENT_TIMESTAMP()),
  ('Supply Chain Anomaly Detection', 'ML models to detect and flag anomalies in supply chain operations, preventing costly disruptions.', 'Supply Chain', 'Operations', 'EFFICIENCY', 8, CURRENT_TIMESTAMP()),
  ('Customer Churn Prediction', 'Predictive model to identify customers at high risk of churning, enabling proactive retention campaigns.', 'Marketing', 'CX', 'REVENUE', 9, CURRENT_TIMESTAMP()),
  ('Visual Search for Products', 'Allow users to search for products using images, improving discovery for visually-driven categories.', 'Retail', 'Commerce', 'REVENUE', 10, CURRENT_TIMESTAMP()),
  ('Automated Document Processing', 'OCR and NLP to extract structured data from invoices, receipts, and contracts, reducing manual data entry.', 'Finance', 'Operations', 'EFFICIENCY', 11, CURRENT_TIMESTAMP()),
  ('HR Candidate Screening', 'AI to screen and rank job applicants based on resume data against job requirements, speeding up recruitment.', 'Human Resources', 'HR', 'EFFICIENCY', 12, CURRENT_TIMESTAMP()),
  ('Sentiment Analysis on Reviews', 'Analyze customer sentiment in product reviews and support tickets to identify product quality issues.', 'Product', 'CX', 'NPS', 13, CURRENT_TIMESTAMP()),
  ('Fraud Detection Engine', 'Real-time transaction monitoring to detect and block fraudulent activities, reducing financial losses.', 'Security', 'Finance', 'EFFICIENCY', 14, CURRENT_TIMESTAMP()),
  ('Personalized Email Campaigns', 'Use customer data to personalize email marketing content and send times, boosting engagement.', 'Marketing', 'Marketing', 'REVENUE', 15, CURRENT_TIMESTAMP()),
  ('IT Helpdesk Ticket Automation', 'LLM-based agent to resolve common IT support requests automatically, freeing up helpdesk staff.', 'IT', 'Operations', 'EFFICIENCY', 16, CURRENT_TIMESTAMP()),
  ('Store Layout Optimization', 'Analyze in-store traffic patterns to optimize product placement and store layout for increased sales.', 'Retail', 'Operations', 'REVENUE', 17, CURRENT_TIMESTAMP()),
  ('Voice of the Customer Analytics', 'Aggregate and analyze customer feedback from all channels to derive actionable product insights.', 'Product', 'CX', 'NPS', 18, CURRENT_TIMESTAMP()),
  ('Energy Consumption Forecasting', 'Predict energy usage in warehouses and stores to optimize procurement and reduce utility costs.', 'Facilities', 'Operations', 'EFFICIENCY', 19, CURRENT_TIMESTAMP()),
  ('Marketing Mix Modeling', 'Attribute marketing spend to sales outcomes to optimize budget allocation across channels.', 'Marketing', 'Marketing', 'REVENUE', 20, CURRENT_TIMESTAMP()),
  ('Code Co-pilot & Review Assistant', 'Developer productivity tools for code generation, completion, and automated pull request reviews.', 'Engineering', 'Technology', 'EFFICIENCY', 21, CURRENT_TIMESTAMP()),
  ('Contact Center Quality Assurance', 'AI to automatically monitor and score agent interactions against quality and compliance rubrics.', 'Customer Service', 'CX', 'NPS', 22, CURRENT_TIMESTAMP()),
  ('Dynamic Pricing Engine', 'Adjust product prices in real-time based on demand, competition, and inventory levels to maximize revenue.', 'Merchandising', 'Commerce', 'REVENUE', 23, CURRENT_TIMESTAMP()),
  ('Logistics Route Optimization', 'Optimize delivery routes for last-mile fleet to reduce fuel costs and improve delivery times.', 'Supply Chain', 'Operations', 'EFFICIENCY', 24, CURRENT_TIMESTAMP()),
  ('Product Recommendation API', 'Provide personalized product recommendations on product detail pages to increase average order value.', 'Retail', 'Commerce', 'REVENUE', 25, CURRENT_TIMESTAMP()),
  ('Employee Retention Risk Model', 'Predict employee attrition risk to allow for targeted interventions by managers and HR.', 'Human Resources', 'HR', 'EFFICIENCY', 26, CURRENT_TIMESTAMP()),
  ('Automated Knowledge Base Writer', 'Generative AI to draft and update internal and external knowledge base articles from support tickets.', 'Customer Service', 'CX', 'NPS', 27, CURRENT_TIMESTAMP()),
  ('A/B Test Analysis Automation', 'Automatically analyze results of A/B tests and provide statistical summaries and recommendations.', 'Product', 'Marketing', 'EFFICIENCY', 28, CURRENT_TIMESTAMP()),
  ('Social Media Trend Identification', 'Monitor social media channels to identify emerging trends and brand mentions in real-time.', 'Marketing', 'Marketing', 'REVENUE', 29, CURRENT_TIMESTAMP()),
  ('Procurement Spend Analytics', 'Analyze procurement data to identify cost-saving opportunities and improve vendor negotiations.', 'Finance', 'Operations', 'EFFICIENCY', 30, CURRENT_TIMESTAMP()),
  ('Website Personalization Engine', 'Dynamically alter website content and layout for individual users to improve engagement.', 'Retail', 'Commerce', 'REVENUE', 31, CURRENT_TIMESTAMP()),
  ('Predictive Maintenance for Fleet', 'Forecast vehicle maintenance needs to prevent breakdowns and optimize service schedules.', 'Supply Chain', 'Operations', 'EFFICIENCY', 32, CURRENT_TIMESTAMP()),
  ('Customer Service Bot Escalation', 'Intelligently decide when to escalate a customer from a bot to a human agent to improve satisfaction.', 'Customer Service', 'CX', 'NPS', 33, CURRENT_TIMESTAMP()),
  ('Financial Anomaly Detection', 'Scan financial records for anomalies that could indicate fraud, error, or non-compliance.', 'Finance', 'Finance', 'EFFICIENCY', 34, CURRENT_TIMESTAMP()),
  ('Ad Creative Generation', 'Use generative AI to create variations of ad images and copy for performance marketing campaigns.', 'Marketing', 'Marketing', 'REVENUE', 35, CURRENT_TIMESTAMP()),
  ('Internal Document Search', 'LLM-powered search across internal documents, wikis, and shared drives.', 'IT', 'Operations', 'EFFICIENCY', 36, CURRENT_TIMESTAMP()),
  ('Customer Lifetime Value (CLV) Prediction', 'Forecast the total revenue a business can expect from a single customer account.', 'Marketing', 'Finance', 'REVENUE', 37, CURRENT_TIMESTAMP()),
  ('Automated Video Content Tagging', 'AI to automatically tag video content with relevant keywords, improving searchability and discovery.', 'Marketing', 'Media', 'EFFICIENCY', 38, CURRENT_TIMESTAMP()),
  ('On-Call Incident Triage', 'Triage and route production engineering alerts to the correct on-call engineer.', 'Engineering', 'Technology', 'EFFICIENCY', 39, CURRENT_TIMESTAMP()),
  ('Personalized In-App Notifications', 'Tailor push notifications and in-app messages based on user behavior to drive specific actions.', 'Product', 'Marketing', 'REVENUE', 40, CURRENT_TIMESTAMP()),
  ('Legal Contract Review AI', 'AI to review legal contracts for standard clauses, risks, and deviations from templates.', 'Legal', 'Operations', 'EFFICIENCY', 41, CURRENT_TIMESTAMP()),
  ('Competitor Price Monitoring', 'Automatically track competitor pricing and promotions to inform pricing strategy.', 'Merchandising', 'Commerce', 'REVENUE', 42, CURRENT_TIMESTAMP()),
  ('Call Center Transcription & Analysis', 'Transcribe and analyze all call center conversations to identify trends and agent performance issues.', 'Customer Service', 'CX', 'NPS', 43, CURRENT_TIMESTAMP()),
  ('Cloud Cost Optimization AI', 'Analyze cloud usage patterns and recommend cost-saving actions like rightsizing and spot instance usage.', 'Engineering', 'Technology', 'EFFICIENCY', 44, CURRENT_TIMESTAMP()),
  ('Product Information Management (PIM) AI', 'Use AI to enrich and standardize product attributes and descriptions in the PIM system.', 'Retail', 'Operations', 'EFFICIENCY', 45, CURRENT_TIMESTAMP()),
  ('Market Basket Analysis', 'Identify products that are frequently purchased together to inform cross-selling and product placement.', 'Retail', 'Commerce', 'REVENUE', 46, CURRENT_TIMESTAMP()),
  ('Employee Survey Analysis', 'NLP to analyze open-ended text from employee engagement surveys to identify key themes.', 'Human Resources', 'HR', 'NPS', 47, CURRENT_TIMESTAMP()),
  ('IT Asset Management AI', 'Predictive models to forecast IT hardware lifecycle and replacement needs.', 'IT', 'Operations', 'EFFICIENCY', 48, CURRENT_TIMESTAMP()),
  ('Next Best Action for Sales', 'Recommend the next best action for sales reps to take with a given customer to advance a deal.', 'Sales', 'Commerce', 'REVENUE', 49, CURRENT_TIMESTAMP()),
  ('Accessibility Issue Detection', 'Automated scanning of web frontends to detect and report accessibility (a11y) issues.', 'Engineering', 'Technology', 'NPS', 50, CURRENT_TIMESTAMP())
  );


-- ── 4. ai_amb_use_case_metric (6 use cases × 5 periods = 30 rows) ────────────
-- All KPI metrics populated for every use case.
-- Primary KPI (per kpi_tag) carries the dominant value; cross-KPI values
-- reflect secondary contributions (e.g. a returns bot also drives efficiency).

INSERT INTO `ai_ambitions.ai_amb_use_case_metric`
  (period, use_case_name, cost_actual, cost_plan, revenue_actual, revenue_plan, nps_actual, nps_plan, efficiency_actual, efficiency_plan, update_ts)
VALUES
  -- ── YTD ──────────────────────────────────────────────────────────────────
  -- Personalized Search: primary REVENUE; secondary NPS (happier discovery) + EFFICIENCY (fewer failed searches)
  ('YTD', 'Personalized Search & Discovery',  6.8, 7.5, 1.8, 2.0, 0.3, 0.4, 0.5,  0.5,  CURRENT_TIMESTAMP()),
  -- Demand Forecast: primary EFFICIENCY; secondary REVENUE (better availability → fewer lost sales)
  ('YTD', 'Demand Forecast v3',               4.8, 5.0, 0.3, 0.3, 0.1, 0.1, 8.5,  10.0, CURRENT_TIMESTAMP()),
  -- Dynamic Markdown: primary REVENUE; secondary EFFICIENCY (faster inventory turn)
  ('YTD', 'Dynamic Markdown Optimization',    4.2, 4.5, 1.2, 1.5, 0.1, 0.2, 1.0,  1.0,  CURRENT_TIMESTAMP()),
  -- Warehouse Slotting: primary EFFICIENCY; secondary NPS (faster delivery) + REVENUE (fewer stock-outs)
  ('YTD', 'Warehouse Slotting AI',            3.6, 4.0, 0.2, 0.2, 0.2, 0.3, 6.2,  8.0,  CURRENT_TIMESTAMP()),
  -- Conv Returns: primary NPS; secondary REVENUE (retention) + EFFICIENCY (agent deflection)
  ('YTD', 'Conversational Returns Assistant', 3.2, 3.5, 0.3, 0.3, 1.4, 1.5, 2.0,  2.0,  CURRENT_TIMESTAMP()),
  -- Chat Triage: primary NPS; secondary EFFICIENCY (lower handle time)
  ('YTD', 'Chat Triage & Routing',            2.4, 2.5, 0.1, 0.1, 0.8, 1.0, 1.5,  1.5,  CURRENT_TIMESTAMP()),
  ('YTD', 'AI-Assisted Content Creation', 2.2, 2.4, 0.1, 0.1, 0.0, 0.0, 1.8, 2.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Supply Chain Anomaly Detection', 2.1, 2.2, 0.1, 0.1, 0.0, 0.0, 1.7, 1.8, CURRENT_TIMESTAMP()),
  ('YTD', 'Customer Churn Prediction', 2.0, 2.1, 0.5, 0.6, 0.1, 0.1, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Visual Search for Products', 1.9, 2.0, 0.4, 0.5, 0.1, 0.1, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Automated Document Processing', 1.8, 1.9, 0.0, 0.0, 0.0, 0.0, 1.6, 1.7, CURRENT_TIMESTAMP()),
  ('YTD', 'HR Candidate Screening', 1.7, 1.8, 0.0, 0.0, 0.0, 0.0, 1.5, 1.6, CURRENT_TIMESTAMP()),
  ('YTD', 'Sentiment Analysis on Reviews', 1.6, 1.7, 0.1, 0.1, 0.4, 0.5, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Fraud Detection Engine', 1.5, 1.6, 0.0, 0.0, 0.0, 0.0, 1.4, 1.5, CURRENT_TIMESTAMP()),
  ('YTD', 'Personalized Email Campaigns', 1.4, 1.5, 0.3, 0.4, 0.1, 0.1, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'IT Helpdesk Ticket Automation', 1.3, 1.4, 0.0, 0.0, 0.1, 0.1, 1.2, 1.3, CURRENT_TIMESTAMP()),
  ('YTD', 'Store Layout Optimization', 1.2, 1.3, 0.2, 0.3, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Voice of the Customer Analytics', 1.1, 1.2, 0.1, 0.1, 0.3, 0.4, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Energy Consumption Forecasting', 1.0, 1.1, 0.0, 0.0, 0.0, 0.0, 1.0, 1.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Marketing Mix Modeling', 0.9, 1.0, 0.2, 0.2, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Code Co-pilot & Review Assistant', 0.8, 0.9, 0.0, 0.0, 0.0, 0.0, 0.9, 1.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Contact Center Quality Assurance', 0.7, 0.8, 0.0, 0.0, 0.2, 0.3, 0.2, 0.2, CURRENT_TIMESTAMP()),
  ('YTD', 'Dynamic Pricing Engine', 0.6, 0.7, 0.1, 0.2, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Logistics Route Optimization', 0.5, 0.6, 0.0, 0.0, 0.0, 0.0, 0.8, 0.9, CURRENT_TIMESTAMP()),
  ('YTD', 'Product Recommendation API', 0.4, 0.5, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Employee Retention Risk Model', 0.3, 0.4, 0.0, 0.0, 0.0, 0.0, 0.7, 0.8, CURRENT_TIMESTAMP()),
  ('YTD', 'Automated Knowledge Base Writer', 0.2, 0.3, 0.0, 0.0, 0.1, 0.2, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'A/B Test Analysis Automation', 0.1, 0.2, 0.0, 0.0, 0.0, 0.0, 0.6, 0.7, CURRENT_TIMESTAMP()),
  ('YTD', 'Social Media Trend Identification', 0.45, 0.5, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Procurement Spend Analytics', 0.35, 0.4, 0.0, 0.0, 0.0, 0.0, 0.5, 0.6, CURRENT_TIMESTAMP()),
  ('YTD', 'Website Personalization Engine', 0.25, 0.3, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Predictive Maintenance for Fleet', 0.15, 0.2, 0.0, 0.0, 0.0, 0.0, 0.4, 0.5, CURRENT_TIMESTAMP()),
  ('YTD', 'Customer Service Bot Escalation', 0.55, 0.6, 0.0, 0.0, 0.1, 0.1, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Financial Anomaly Detection', 0.65, 0.7, 0.0, 0.0, 0.0, 0.0, 0.3, 0.4, CURRENT_TIMESTAMP()),
  ('YTD', 'Ad Creative Generation', 0.75, 0.8, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Internal Document Search', 0.85, 0.9, 0.0, 0.0, 0.0, 0.0, 0.2, 0.3, CURRENT_TIMESTAMP()),
  ('YTD', 'Customer Lifetime Value (CLV) Prediction', 0.95, 1.0, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Automated Video Content Tagging', 1.05, 1.1, 0.0, 0.0, 0.0, 0.0, 0.1, 0.2, CURRENT_TIMESTAMP()),
  ('YTD', 'On-Call Incident Triage', 1.15, 1.2, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Personalized In-App Notifications', 1.25, 1.3, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Legal Contract Review AI', 1.35, 1.4, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Competitor Price Monitoring', 1.45, 1.5, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Call Center Transcription & Analysis', 1.55, 1.6, 0.0, 0.0, 0.1, 0.1, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Cloud Cost Optimization AI', 1.65, 1.7, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Product Information Management (PIM) AI', 1.75, 1.8, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Market Basket Analysis', 1.85, 1.9, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Employee Survey Analysis', 1.95, 2.0, 0.0, 0.0, 0.1, 0.1, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'IT Asset Management AI', 2.05, 2.1, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, CURRENT_TIMESTAMP()),
  ('YTD', 'Next Best Action for Sales', 2.15, 2.2, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Accessibility Issue Detection', 2.25, 2.3, 0.0, 0.0, 0.1, 0.1, 0.0, 0.0, CURRENT_TIMESTAMP()),

  -- ── Q1 ───────────────────────────────────────────────────────────────────
  ('Q1',  'Personalized Search & Discovery',  1.5, 1.9, 0.8, 1.0, 0.1, 0.1, 0.1,  0.1,  CURRENT_TIMESTAMP()),
  ('Q1',  'Demand Forecast v3',               1.1, 1.2, 0.1, 0.1, 0.0, 0.0, 3.5,  4.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Dynamic Markdown Optimization',    0.9, 1.1, 0.5, 0.6, 0.0, 0.1, 0.2,  0.2,  CURRENT_TIMESTAMP()),
  ('Q1',  'Warehouse Slotting AI',            0.8, 1.0, 0.1, 0.1, 0.1, 0.1, 2.5,  3.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Conversational Returns Assistant', 0.7, 0.9, 0.1, 0.1, 0.5, 0.6, 0.5,  0.5,  CURRENT_TIMESTAMP()),
  ('Q1',  'Chat Triage & Routing',            0.5, 0.5, 0.0, 0.0, 0.3, 0.4, 0.3,  0.3,  CURRENT_TIMESTAMP()),

  -- ── Q2 ───────────────────────────────────────────────────────────────────
  ('Q2',  'Personalized Search & Discovery',  1.8, 1.9, 1.0, 1.0, 0.1, 0.1, 0.1,  0.1,  CURRENT_TIMESTAMP()),
  ('Q2',  'Demand Forecast v3',               1.3, 1.2, 0.1, 0.1, 0.0, 0.0, 5.0,  5.5,  CURRENT_TIMESTAMP()),
  ('Q2',  'Dynamic Markdown Optimization',    1.1, 1.1, 0.7, 0.7, 0.0, 0.1, 0.3,  0.3,  CURRENT_TIMESTAMP()),
  ('Q2',  'Warehouse Slotting AI',            1.0, 1.0, 0.1, 0.1, 0.1, 0.1, 3.8,  4.2,  CURRENT_TIMESTAMP()),
  ('Q2',  'Conversational Returns Assistant', 0.9, 0.9, 0.1, 0.1, 0.7, 0.7, 0.5,  0.5,  CURRENT_TIMESTAMP()),
  ('Q2',  'Chat Triage & Routing',            0.7, 0.6, 0.0, 0.0, 0.4, 0.4, 0.4,  0.4,  CURRENT_TIMESTAMP()),

  -- ── Q3 ───────────────────────────────────────────────────────────────────
  ('Q3',  'Personalized Search & Discovery',  2.2, 1.9, 1.2, 1.0, 0.1, 0.1, 0.2,  0.1,  CURRENT_TIMESTAMP()),
  ('Q3',  'Demand Forecast v3',               1.6, 1.2, 0.1, 0.1, 0.0, 0.0, 6.5,  6.0,  CURRENT_TIMESTAMP()),
  ('Q3',  'Dynamic Markdown Optimization',    1.3, 1.1, 0.9, 0.8, 0.0, 0.1, 0.3,  0.3,  CURRENT_TIMESTAMP()),
  ('Q3',  'Warehouse Slotting AI',            1.1, 1.0, 0.0, 0.1, 0.1, 0.1, 5.0,  4.8,  CURRENT_TIMESTAMP()),
  ('Q3',  'Conversational Returns Assistant', 1.0, 0.9, 0.1, 0.1, 0.8, 0.7, 0.6,  0.5,  CURRENT_TIMESTAMP()),
  ('Q3',  'Chat Triage & Routing',            0.8, 0.6, 0.0, 0.0, 0.5, 0.4, 0.4,  0.3,  CURRENT_TIMESTAMP()),

  -- ── Q4 ───────────────────────────────────────────────────────────────────
  ('Q4',  'Personalized Search & Discovery',  1.3, 1.9, 0.6, 1.0, 0.1, 0.1, 0.1,  0.2,  CURRENT_TIMESTAMP()),
  ('Q4',  'Demand Forecast v3',               0.8, 1.2, 0.0, 0.1, 0.0, 0.0, 2.5,  5.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Dynamic Markdown Optimization',    0.9, 1.1, 0.4, 0.8, 0.0, 0.1, 0.2,  0.3,  CURRENT_TIMESTAMP()),
  ('Q4',  'Warehouse Slotting AI',            0.7, 1.0, 0.0, 0.1, 0.0, 0.1, 1.8,  4.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Conversational Returns Assistant', 0.6, 0.9, 0.1, 0.1, 0.4, 0.6, 0.5,  0.5,  CURRENT_TIMESTAMP()),
  ('Q4',  'Chat Triage & Routing',            0.2, 0.5, 0.0, 0.0, 0.2, 0.4, 0.2,  0.3,  CURRENT_TIMESTAMP());
