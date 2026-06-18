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
  );


-- ── 4. ai_amb_use_case_metric (6 use cases × 5 periods = 30 rows) ────────────
-- Non-primary KPI metrics are 0.0 — only the kpi_tag metric carries real values.

INSERT INTO `ai_ambitions.ai_amb_use_case_metric`
  (period, use_case_name, cost_actual, cost_plan, revenue_actual, revenue_plan, nps_actual, nps_plan, efficiency_actual, efficiency_plan, update_ts)
VALUES
  -- ── YTD ──────────────────────────────────────────────────────────────────
  ('YTD', 'Personalized Search & Discovery',  6.8, 7.5, 1.8, 2.0, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'Demand Forecast v3',               4.8, 5.0, 0.0, 0.0, 0.0, 0.0, 8.5,  10.0, CURRENT_TIMESTAMP()),
  ('YTD', 'Dynamic Markdown Optimization',    4.2, 4.5, 1.2, 1.5, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'Warehouse Slotting AI',            3.6, 4.0, 0.0, 0.0, 0.0, 0.0, 6.2,  8.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'Conversational Returns Assistant', 3.2, 3.5, 0.0, 0.0, 1.4, 1.5, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('YTD', 'Chat Triage & Routing',            2.4, 2.5, 0.0, 0.0, 0.8, 1.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),

  -- ── Q1 ───────────────────────────────────────────────────────────────────
  ('Q1',  'Personalized Search & Discovery',  1.5, 1.9, 0.8, 1.0, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Demand Forecast v3',               1.1, 1.2, 0.0, 0.0, 0.0, 0.0, 3.5,  4.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Dynamic Markdown Optimization',    0.9, 1.1, 0.5, 0.6, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Warehouse Slotting AI',            0.8, 1.0, 0.0, 0.0, 0.0, 0.0, 2.5,  3.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Conversational Returns Assistant', 0.7, 0.9, 0.0, 0.0, 0.5, 0.6, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q1',  'Chat Triage & Routing',            0.5, 0.5, 0.0, 0.0, 0.3, 0.4, 0.0,  0.0,  CURRENT_TIMESTAMP()),

  -- ── Q2 ───────────────────────────────────────────────────────────────────
  ('Q2',  'Personalized Search & Discovery',  1.8, 1.9, 1.0, 1.0, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q2',  'Demand Forecast v3',               1.3, 1.2, 0.0, 0.0, 0.0, 0.0, 5.0,  5.5,  CURRENT_TIMESTAMP()),
  ('Q2',  'Dynamic Markdown Optimization',    1.1, 1.1, 0.7, 0.7, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q2',  'Warehouse Slotting AI',            1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 3.8,  4.2,  CURRENT_TIMESTAMP()),
  ('Q2',  'Conversational Returns Assistant', 0.9, 0.9, 0.0, 0.0, 0.7, 0.7, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q2',  'Chat Triage & Routing',            0.7, 0.6, 0.0, 0.0, 0.4, 0.4, 0.0,  0.0,  CURRENT_TIMESTAMP()),

  -- ── Q3 ───────────────────────────────────────────────────────────────────
  ('Q3',  'Personalized Search & Discovery',  2.2, 1.9, 1.2, 1.0, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q3',  'Demand Forecast v3',               1.6, 1.2, 0.0, 0.0, 0.0, 0.0, 6.5,  6.0,  CURRENT_TIMESTAMP()),
  ('Q3',  'Dynamic Markdown Optimization',    1.3, 1.1, 0.9, 0.8, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q3',  'Warehouse Slotting AI',            1.1, 1.0, 0.0, 0.0, 0.0, 0.0, 5.0,  4.8,  CURRENT_TIMESTAMP()),
  ('Q3',  'Conversational Returns Assistant', 1.0, 0.9, 0.0, 0.0, 0.8, 0.7, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q3',  'Chat Triage & Routing',            0.8, 0.6, 0.0, 0.0, 0.5, 0.4, 0.0,  0.0,  CURRENT_TIMESTAMP()),

  -- ── Q4 ───────────────────────────────────────────────────────────────────
  ('Q4',  'Personalized Search & Discovery',  1.3, 1.9, 0.6, 1.0, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Demand Forecast v3',               0.8, 1.2, 0.0, 0.0, 0.0, 0.0, 2.5,  5.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Dynamic Markdown Optimization',    0.9, 1.1, 0.4, 0.8, 0.0, 0.0, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Warehouse Slotting AI',            0.7, 1.0, 0.0, 0.0, 0.0, 0.0, 1.8,  4.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Conversational Returns Assistant', 0.6, 0.9, 0.0, 0.0, 0.4, 0.6, 0.0,  0.0,  CURRENT_TIMESTAMP()),
  ('Q4',  'Chat Triage & Routing',            0.2, 0.5, 0.0, 0.0, 0.2, 0.4, 0.0,  0.0,  CURRENT_TIMESTAMP());
