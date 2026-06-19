-- ─────────────────────────────────────────────────────────────────────────────
-- AI Ambitions Dashboard — Seed Data (YTD only)
-- Run AFTER schema.sql
--
-- KPI headline numbers:
--   AI Cost  : $38.5M actual  / $42.0M plan  → UNDER PLAN
--   Revenue  :   2.1% actual  /   4.5% plan  → BELOW TARGET (band 3–7%)
--   NPS      :   3.4 pts      /   3.0 plan   → IN BAND (band 2–4 pts)
--   Efficiency:   36% actual  /   32% plan   → IN BAND (band 30–40%)
--
-- 100 use cases: each contributes to NONE, ONE, or TWO of (revenue, nps, efficiency).
-- No use case contributes to all three.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. KPI Summary ────────────────────────────────────────────────────────────

INSERT INTO `ai_ambitions.ai_amb_kpi_summary`
  (period, kpi_id, actual_value, plan_value, actual_delta, delta_label, update_ts)
VALUES
  ('YTD', 'ai-cost',    38.5, 42.0, -3.5, 'vs plan', CURRENT_TIMESTAMP()),
  ('YTD', 'revenue',     2.1,  4.5,  0.3, 'vs Q4',   CURRENT_TIMESTAMP()),
  ('YTD', 'nps',         3.4,  3.0,  0.5, 'vs Q4',   CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 36.0, 32.0,  4.0, 'vs Q4',   CURRENT_TIMESTAMP());


-- ── 2. Dimension Metrics — YTD ────────────────────────────────────────────────
-- Categories = AI investment types; values show each type's contribution
-- to both spend ($M) and KPI outcomes (%, pts).
-- Vendors = AI platform/tool vendors.

INSERT INTO `ai_ambitions.ai_amb_dimension_metrics`
  (period, metric_id, dimension_type, dimension_name, actual_value, plan_value, update_ts)
VALUES
  -- ── Cost by category ($M) ────────────────────────────────────────────────
  ('YTD', 'cost', 'category', 'Foundation Model Inference', 16.6, 18.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Cloud Compute & Storage',    10.4, 11.2, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Data Labeling & Ops',         5.1,  5.8, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Platform & MLOps Tooling',    3.7,  4.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'category', 'Talent Allocation',            2.7,  3.2, CURRENT_TIMESTAMP()),

  -- ── Cost by vendor ($M) ──────────────────────────────────────────────────
  ('YTD', 'cost', 'vendor', 'Google Cloud (Vertex AI)',    12.8, 14.0, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'OpenAI / Azure OpenAI',        8.8,  9.5, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'AWS Bedrock',                   6.8,  7.2, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Scale AI (Data Labeling)',      5.1,  5.8, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Databricks',                    2.9,  3.2, CURRENT_TIMESTAMP()),
  ('YTD', 'cost', 'vendor', 'Others',                        2.1,  2.5, CURRENT_TIMESTAMP()),

  -- ── Revenue by category (%) ──────────────────────────────────────────────
  ('YTD', 'revenue', 'category', 'Foundation Model Inference', 0.80, 0.92, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Cloud Compute & Storage',    0.48, 0.55, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Data Labeling & Ops',        0.38, 0.44, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Platform & MLOps Tooling',   0.25, 0.29, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'category', 'Talent Allocation',           0.19, 0.22, CURRENT_TIMESTAMP()),

  -- ── Revenue by vendor (%) ────────────────────────────────────────────────
  ('YTD', 'revenue', 'vendor', 'Google Cloud (Vertex AI)',    0.72, 0.83, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'OpenAI / Azure OpenAI',       0.65, 0.75, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'AWS Bedrock',                  0.31, 0.36, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'Scale AI (Data Labeling)',     0.22, 0.25, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'Databricks',                   0.12, 0.14, CURRENT_TIMESTAMP()),
  ('YTD', 'revenue', 'vendor', 'Others',                       0.08, 0.09, CURRENT_TIMESTAMP()),

  -- ── NPS by category (pts) ────────────────────────────────────────────────
  ('YTD', 'nps', 'category', 'Foundation Model Inference', 1.20, 1.05, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Cloud Compute & Storage',    0.72, 0.63, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Data Labeling & Ops',        0.58, 0.51, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Platform & MLOps Tooling',   0.50, 0.44, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'category', 'Talent Allocation',           0.40, 0.35, CURRENT_TIMESTAMP()),

  -- ── NPS by vendor (pts) ──────────────────────────────────────────────────
  ('YTD', 'nps', 'vendor', 'Google Cloud (Vertex AI)',    1.22, 1.07, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'OpenAI / Azure OpenAI',       1.02, 0.90, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'AWS Bedrock',                  0.58, 0.51, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'Scale AI (Data Labeling)',     0.32, 0.28, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'Databricks',                   0.18, 0.16, CURRENT_TIMESTAMP()),
  ('YTD', 'nps', 'vendor', 'Others',                       0.08, 0.07, CURRENT_TIMESTAMP()),

  -- ── Efficiency by category (%) ───────────────────────────────────────────
  ('YTD', 'efficiency', 'category', 'Foundation Model Inference', 12.0, 10.5, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Cloud Compute & Storage',     8.0,  7.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Data Labeling & Ops',          6.5,  5.7, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Platform & MLOps Tooling',     5.5,  4.8, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'category', 'Talent Allocation',             4.0,  3.5, CURRENT_TIMESTAMP()),

  -- ── Efficiency by vendor (%) ─────────────────────────────────────────────
  ('YTD', 'efficiency', 'vendor', 'Google Cloud (Vertex AI)',    12.8, 11.2, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'OpenAI / Azure OpenAI',        9.2,  8.0, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'AWS Bedrock',                   7.0,  6.1, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'Scale AI (Data Labeling)',      4.0,  3.5, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'Databricks',                    2.2,  1.9, CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency', 'vendor', 'Others',                        0.8,  0.7, CURRENT_TIMESTAMP());


-- ── 3. Use Case Data — YTD ───────────────────────────────────────────────────
-- 100 use cases.  KPI columns are NULL when the use case does not contribute.
-- cost_plan ≈ cost_actual × 1.08  (mostly under plan)
-- rev_plan  ≈ rev_actual  × 1.15  (below plan, consistent with headline status)
-- nps_plan  ≈ nps_actual  × 0.88  (actual exceeds plan → good)
-- eff_plan  ≈ eff_actual  × 0.88  (actual exceeds plan → good)

INSERT INTO `ai_ambitions.ai_amb_use_case_data`
  (period, use_case, description, csg, functional_area,
   cost_actual, cost_plan,
   revenue_actual, revenue_plan,
   nps_actual,     nps_plan,
   efficiency_actual, efficiency_plan,
   update_ts)
VALUES

  -- ── Group A: Cost only — no KPI contribution (20 use cases) ──────────────

  ('YTD', 'AI Infrastructure Foundation',
   'Core AI compute, networking and storage platform underpinning all AI initiatives.',
   'Corporate', 'Technology', 1.60, 1.73, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'MLOps Platform & Tooling',
   'Automated pipelines for model training, deployment and monitoring at scale.',
   'Corporate', 'Technology', 1.30, 1.40, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Data Labeling & Annotation Pipeline',
   'High-quality labeled data production for supervised learning across all domains.',
   'Corporate', 'Technology', 1.10, 1.19, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Foundation Model API Gateway',
   'Centralized proxy for managing, routing and rate-limiting foundation model API calls.',
   'Corporate', 'Technology', 0.90, 0.97, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Security & Compliance Framework',
   'Security controls, audit logging and compliance tooling for all AI workloads.',
   'Corporate', 'Security', 0.65, 0.70, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Experimentation Platform',
   'Managed sandbox for rapid hypothesis testing and model prototyping by data scientists.',
   'Corporate', 'Technology', 0.60, 0.65, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Feature Store Implementation',
   'Centralized repository for storing, versioning and serving ML features in real time.',
   'Corporate', 'Technology', 0.50, 0.54, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Model Registry & Versioning',
   'Catalog tracking all trained models, their lineage, hyperparameters and promotion status.',
   'Corporate', 'Technology', 0.45, 0.49, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Observability & Monitoring',
   'Dashboard and alerting layer for model performance drift and data quality degradation.',
   'Corporate', 'Technology', 0.38, 0.41, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Vector Database Infrastructure',
   'Low-latency vector similarity search layer powering semantic search and RAG pipelines.',
   'Corporate', 'Technology', 0.36, 0.39, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'GPU Cluster Management',
   'Scheduling, autoscaling and cost allocation for shared GPU compute across teams.',
   'Corporate', 'Technology', 0.30, 0.32, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Model Governance Tooling',
   'Policy enforcement, explainability reports and bias assessments for deployed models.',
   'Corporate', 'Security', 0.28, 0.30, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Synthetic Data Generation Platform',
   'Generates privacy-safe synthetic datasets to augment scarce training data.',
   'Corporate', 'Technology', 0.22, 0.24, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Center of Excellence',
   'Cross-functional team setting AI strategy, standards and best practices company-wide.',
   'Corporate', 'HR', 0.20, 0.22, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Ethics & Bias Testing Framework',
   'Systematic testing suite that surfaces fairness and bias issues before model deployment.',
   'Corporate', 'Security', 0.18, 0.19, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Prompt Engineering Tooling',
   'IDE and version-control tooling for authoring, testing and deploying LLM prompt templates.',
   'Corporate', 'Technology', 0.15, 0.16, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Documentation Hub',
   'Centralized knowledge base for AI runbooks, architecture diagrams and onboarding guides.',
   'Corporate', 'Technology', 0.12, 0.13, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Vendor Management System',
   'Tracks AI vendor contracts, SLAs, pricing tiers and renewal calendars.',
   'Corporate', 'Operations', 0.11, 0.12, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Benchmark Testing Suite',
   'Automated benchmark harness measuring model accuracy, latency and cost regressions.',
   'Corporate', 'Technology', 0.08, 0.09, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Data Platform Modernization',
   'Migration of legacy data pipelines to modern lakehouse architecture enabling AI workloads.',
   'Corporate', 'Technology', 0.08, 0.09, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group B: Revenue only (15 use cases) ─────────────────────────────────

  ('YTD', 'Personalized Search & Discovery',
   'Semantic search and personalized result ranking to increase conversion from site search.',
   'Consumer', 'Commerce', 1.30, 1.40, 0.25, 0.29, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Pricing Engine',
   'Real-time demand-aware pricing model that maximizes revenue per unit.',
   'Consumer', 'Commerce', 1.00, 1.08, 0.20, 0.23, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Market Basket Analysis',
   'Identifies co-purchase patterns to drive bundled promotions and cross-category revenue.',
   'Consumer', 'Commerce', 0.80, 0.86, 0.16, 0.18, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Product Recommendation API',
   'Collaborative-filtering API serving personalized product recommendations across all channels.',
   'Consumer', 'Commerce', 0.65, 0.70, 0.13, 0.15, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Markdown Optimization',
   'ML model scheduling optimal discount timing and depth to maximize margin recovery.',
   'Business', 'Finance', 0.58, 0.63, 0.11, 0.13, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Next Best Action for Sales',
   'Recommends the highest-probability-to-close action for each sales opportunity in CRM.',
   'Business', 'Commerce', 0.52, 0.56, 0.10, 0.12, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Marketing Mix Modeling',
   'Attribution model allocating revenue credit across channels to optimize marketing spend.',
   'Consumer', 'Marketing', 0.44, 0.48, 0.08, 0.09, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Lead Scoring Model',
   'Predicts likelihood of B2B lead conversion, prioritizing sales outreach.',
   'Business', 'Commerce', 0.36, 0.39, 0.07, 0.08, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Competitor Price Monitoring',
   'Scrapes and tracks competitor pricing, feeding real-time signals to the pricing engine.',
   'Consumer', 'Commerce', 0.30, 0.32, 0.05, 0.06, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Ad Creative Generation',
   'Generative AI producing ad copy and creative variants for A/B testing at scale.',
   'Consumer', 'Marketing', 0.28, 0.30, 0.05, 0.06, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Email Campaigns',
   'Sends individually tailored offers and content based on customer purchase history.',
   'Consumer', 'Marketing', 0.25, 0.27, 0.04, 0.05, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Assisted Sales Forecasting',
   'Improves quarterly revenue forecast accuracy using ML on pipeline and external signals.',
   'Business', 'Finance', 0.22, 0.24, 0.04, 0.05, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Subscription Propensity Modeling',
   'Predicts which customers are most likely to upgrade to premium plans.',
   'Consumer', 'Marketing', 0.22, 0.24, 0.04, 0.05, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Website Personalization Engine',
   'Dynamically adapts homepage banners and product carousels per visitor segment.',
   'Consumer', 'Commerce', 0.18, 0.19, 0.03, 0.03, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Store Layout Optimization',
   'Recommends shelf and end-cap placements to maximize in-store purchase probability.',
   'Consumer', 'Operations', 0.14, 0.15, 0.02, 0.02, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group C: NPS only (15 use cases) ─────────────────────────────────────

  ('YTD', 'Conversational Returns Assistant',
   'AI chatbot guiding customers through returns, reducing handling time and friction.',
   'Consumer', 'CX', 1.20, 1.30, NULL, NULL, 0.38, 0.33, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Chat Triage & Routing',
   'Classifies incoming chat intents and routes to the best-available agent or bot.',
   'Consumer', 'CX', 0.88, 0.95, NULL, NULL, 0.28, 0.25, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Contact Center Quality Assurance',
   'Auto-scores 100% of agent interactions against quality rubrics, replacing sampling.',
   'Consumer', 'CX', 0.66, 0.71, NULL, NULL, 0.22, 0.19, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Voice of the Customer Analytics',
   'Synthesizes NPS verbatims, reviews and social mentions into weekly action themes.',
   'Consumer', 'CX', 0.52, 0.56, NULL, NULL, 0.17, 0.15, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Sentiment Analysis on Reviews',
   'Real-time classification of product and service reviews by sentiment and topic.',
   'Consumer', 'CX', 0.44, 0.48, NULL, NULL, 0.14, 0.12, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Real-time Language Translation',
   'Enables multilingual support conversations without requiring specialist agents.',
   'Consumer', 'CX', 0.36, 0.39, NULL, NULL, 0.11, 0.10, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Service Bot Escalation',
   'Detects customer frustration signals and escalates to human agents at the right moment.',
   'Consumer', 'CX', 0.33, 0.36, NULL, NULL, 0.10, 0.09, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Loyalty Program Rewards',
   'Tailors reward offers to individual redemption likelihood to boost program engagement.',
   'Consumer', 'Marketing', 0.30, 0.32, NULL, NULL, 0.09, 0.08, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Voice-based In-store Assistant',
   'Ambient voice assistant in stores answering product, price and location queries.',
   'Consumer', 'CX', 0.26, 0.28, NULL, NULL, 0.07, 0.06, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Accessibility Issue Detection',
   'Automated scanner identifying WCAG accessibility failures across digital products.',
   'Corporate', 'Technology', 0.22, 0.24, NULL, NULL, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Call Center Transcription & Analysis',
   'Transcribes calls in real time, surfacing insights for agent coaching and compliance.',
   'Consumer', 'CX', 0.22, 0.24, NULL, NULL, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Social Media Content Moderation',
   'Classifies and prioritizes policy violations in user-generated social content.',
   'Consumer', 'Marketing', 0.18, 0.19, NULL, NULL, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Employee Survey Analysis',
   'NLP analysis of employee engagement surveys, surfacing key themes for HR action.',
   'Corporate', 'HR', 0.15, 0.16, NULL, NULL, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Feedback Topic Modeling',
   'Clusters open-ended feedback into actionable topics by product or journey stage.',
   'Consumer', 'CX', 0.15, 0.16, NULL, NULL, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Financial Advice Bot',
   'Conversational assistant providing tailored financial product recommendations.',
   'Business', 'CX', 0.11, 0.12, NULL, NULL, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group D: Efficiency only (15 use cases) ───────────────────────────────

  ('YTD', 'Demand Forecast v3',
   'Next-generation demand signal model combining internal sell-through with external macro signals.',
   'Business', 'Operations', 1.02, 1.10, NULL, NULL, NULL, NULL, 3.80, 3.34, CURRENT_TIMESTAMP()),

  ('YTD', 'Warehouse Slotting AI',
   'Optimizes pick-path layout in fulfillment centers to minimize travel time.',
   'Business', 'Operations', 0.88, 0.95, NULL, NULL, NULL, NULL, 3.20, 2.82, CURRENT_TIMESTAMP()),

  ('YTD', 'Logistics Route Optimization',
   'Dynamic last-mile routing that reduces fuel cost and delivery time simultaneously.',
   'Business', 'Operations', 0.66, 0.71, NULL, NULL, NULL, NULL, 2.80, 2.46, CURRENT_TIMESTAMP()),

  ('YTD', 'Fraud Detection Engine',
   'Real-time transaction scoring model reducing fraud losses while minimizing false declines.',
   'Corporate', 'Finance', 0.51, 0.55, NULL, NULL, NULL, NULL, 2.20, 1.94, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Document Processing',
   'IDP pipeline extracting structured data from invoices, contracts and forms at scale.',
   'Corporate', 'Operations', 0.44, 0.48, NULL, NULL, NULL, NULL, 1.80, 1.58, CURRENT_TIMESTAMP()),

  ('YTD', 'HR Candidate Screening',
   'Anonymized CV ranking model reducing time-to-shortlist for high-volume roles.',
   'Corporate', 'HR', 0.36, 0.39, NULL, NULL, NULL, NULL, 1.50, 1.32, CURRENT_TIMESTAMP()),

  ('YTD', 'Energy Consumption Forecasting',
   '24-hour load forecast model enabling smarter energy procurement and grid management.',
   'Corporate', 'Operations', 0.33, 0.36, NULL, NULL, NULL, NULL, 1.30, 1.14, CURRENT_TIMESTAMP()),

  ('YTD', 'Code Co-pilot & Review Assistant',
   'In-IDE LLM assistant accelerating developer velocity and catching code issues early.',
   'Corporate', 'Technology', 0.29, 0.31, NULL, NULL, NULL, NULL, 1.10, 0.97, CURRENT_TIMESTAMP()),

  ('YTD', 'A/B Test Analysis Automation',
   'Automated Bayesian experiment analyzer that eliminates manual stats review delays.',
   'Consumer', 'Marketing', 0.26, 0.28, NULL, NULL, NULL, NULL, 0.90, 0.79, CURRENT_TIMESTAMP()),

  ('YTD', 'Procurement Spend Analytics',
   'Classifies and benchmarks spend to surface consolidation and renegotiation opportunities.',
   'Corporate', 'Finance', 0.22, 0.24, NULL, NULL, NULL, NULL, 0.80, 0.70, CURRENT_TIMESTAMP()),

  ('YTD', 'Predictive Maintenance for Fleet',
   'Anomaly detection on vehicle telematics data to prevent unplanned downtime.',
   'Business', 'Operations', 0.22, 0.24, NULL, NULL, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'Financial Anomaly Detection',
   'Flags unusual GL transactions for finance review, reducing month-end close time.',
   'Corporate', 'Finance', 0.18, 0.19, NULL, NULL, NULL, NULL, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'Cloud Cost Optimization AI',
   'Continuously right-sizes cloud resources and identifies idle or over-provisioned assets.',
   'Corporate', 'Technology', 0.15, 0.16, NULL, NULL, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'IT Helpdesk Ticket Automation',
   'Auto-classifies, prioritizes and resolves Tier-1 IT tickets without human involvement.',
   'Corporate', 'Technology', 0.15, 0.16, NULL, NULL, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'Legal Contract Review AI',
   'Extracts obligations and flags non-standard clauses in contracts for legal review.',
   'Corporate', 'Legal', 0.11, 0.12, NULL, NULL, NULL, NULL, 0.30, 0.26, CURRENT_TIMESTAMP()),

  -- ── Group E: Revenue + NPS (12 use cases) ────────────────────────────────

  ('YTD', 'Visual Search for Products',
   'Lets customers search by image, increasing discovery and conversion for hard-to-describe items.',
   'Consumer', 'Commerce', 0.66, 0.71, 0.09, 0.10, 0.12, 0.11, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized In-App Notifications',
   'Sends contextually relevant push notifications based on real-time behavior signals.',
   'Consumer', 'Marketing', 0.51, 0.55, 0.07, 0.08, 0.09, 0.08, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Social Media Trend Identification',
   'Detects emerging trends from social data to inform content and product decisions.',
   'Consumer', 'Marketing', 0.37, 0.40, 0.05, 0.06, 0.07, 0.06, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Ad Targeting',
   'Real-time audience targeting model optimizing ad spend allocation across digital channels.',
   'Consumer', 'Marketing', 0.33, 0.36, 0.05, 0.06, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Marketing Offer Generation',
   'Creates individualized promotional offers predicted to drive highest incremental revenue.',
   'Consumer', 'Marketing', 0.29, 0.31, 0.04, 0.05, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Upsell/Cross-sell Recommendation Engine',
   'Surfaces next-best-product recommendations at checkout to increase basket size.',
   'Consumer', 'Commerce', 0.29, 0.31, 0.04, 0.05, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Content Feed',
   'Ranks editorial and product content per user to maximize engagement and session depth.',
   'Consumer', 'Commerce', 0.26, 0.28, 0.03, 0.03, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Powered Merchandising Allocation',
   'Optimizes inventory allocation across channels and geographies to reduce stockouts.',
   'Business', 'Commerce', 0.22, 0.24, 0.03, 0.03, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Ad Copy Performance Testing',
   'Runs multivariate ad copy experiments and auto-promotes best-performing variants.',
   'Consumer', 'Marketing', 0.18, 0.19, 0.02, 0.02, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Journey Orchestration',
   'Coordinates cross-channel outreach timing and content to guide customers toward purchase.',
   'Consumer', 'CX', 0.15, 0.16, 0.02, 0.02, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Customer Offer Engine',
   'Real-time offer engine personalizing promotions at every digital touchpoint.',
   'Consumer', 'Marketing', 0.44, 0.48, 0.06, 0.07, 0.08, 0.07, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Omnichannel AI Orchestration Platform',
   'Master AI layer coordinating personalization signals across web, app and in-store.',
   'Consumer', 'Technology', 0.18, 0.19, 0.03, 0.03, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group F: Revenue + Efficiency (12 use cases) ─────────────────────────

  ('YTD', 'Supply Chain Anomaly Detection',
   'Identifies disruption signals early, enabling proactive mitigation of supply shortfalls.',
   'Business', 'Operations', 0.51, 0.55, 0.06, 0.07, NULL, NULL, 1.00, 0.88, CURRENT_TIMESTAMP()),

  ('YTD', 'Product Defect Detection',
   'Computer-vision inspection model on the production line, reducing defect escape rate.',
   'Business', 'Operations', 0.40, 0.43, 0.05, 0.06, NULL, NULL, 0.80, 0.70, CURRENT_TIMESTAMP()),

  ('YTD', 'Marketing Campaign Lookalike Modeling',
   'Builds high-value audience lookalikes from first-party data for paid media.',
   'Consumer', 'Marketing', 0.37, 0.40, 0.04, 0.05, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Lifetime Value Prediction',
   'Scores each customer predicted LTV to prioritize retention and acquisition spend.',
   'Consumer', 'Finance', 0.33, 0.36, 0.04, 0.05, NULL, NULL, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Ad Content Optimization',
   'Real-time creative optimization adjusting ad content elements to maximize CTR.',
   'Consumer', 'Marketing', 0.29, 0.31, 0.03, 0.03, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Powered Inventory Allocation',
   'Distributes available inventory across fulfillment nodes to minimize split shipments.',
   'Business', 'Operations', 0.26, 0.28, 0.03, 0.03, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'Price Elasticity Modeling',
   'Quantifies demand sensitivity to price changes to inform optimal price-setting strategy.',
   'Business', 'Finance', 0.22, 0.24, 0.02, 0.02, NULL, NULL, 0.35, 0.31, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Invoice Reconciliation',
   'Matches purchase orders, delivery receipts and invoices to resolve discrepancies automatically.',
   'Corporate', 'Finance', 0.18, 0.19, 0.02, 0.02, NULL, NULL, 0.28, 0.25, CURRENT_TIMESTAMP()),

  ('YTD', 'Predictive Cash Flow Forecasting',
   '90-day cash flow forecast model improving treasury planning accuracy.',
   'Corporate', 'Finance', 0.15, 0.16, 0.02, 0.02, NULL, NULL, 0.22, 0.19, CURRENT_TIMESTAMP()),

  ('YTD', 'Workforce Demand Planning AI',
   'Forecasts staffing demand by role and region, reducing over- and under-hiring.',
   'Corporate', 'HR', 0.11, 0.12, 0.01, 0.01, NULL, NULL, 0.15, 0.13, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Search & Recommendation Hub',
   'Unified platform combining semantic search and collaborative filtering across all properties.',
   'Consumer', 'Commerce', 0.59, 0.64, 0.08, 0.09, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Contract Lifecycle Management',
   'End-to-end AI platform automating contract drafting, review, approval and renewal.',
   'Corporate', 'Legal', 0.26, 0.28, 0.04, 0.05, NULL, NULL, 0.35, 0.31, CURRENT_TIMESTAMP()),

  -- ── Group G: NPS + Efficiency (11 use cases) ─────────────────────────────

  ('YTD', 'Customer Service Agent Assist',
   'Real-time knowledge panel surfacing answers and next-best-actions for live agents.',
   'Consumer', 'CX', 0.59, 0.64, NULL, NULL, 0.18, 0.16, 1.40, 1.23, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Knowledge Base Writer',
   'Generates and updates help-center articles from resolved ticket transcripts.',
   'Consumer', 'CX', 0.44, 0.48, NULL, NULL, 0.14, 0.12, 1.10, 0.97, CURRENT_TIMESTAMP()),

  ('YTD', 'IT Service Management Automation',
   'AI-driven ITSM that auto-resolves incidents, changes and problems from pattern history.',
   'Corporate', 'Technology', 0.37, 0.40, NULL, NULL, 0.10, 0.09, 0.90, 0.79, CURRENT_TIMESTAMP()),

  ('YTD', 'Smart Building Energy Management',
   'Adjusts HVAC and lighting dynamically to minimize energy use while maintaining comfort.',
   'Corporate', 'Operations', 0.29, 0.31, NULL, NULL, 0.08, 0.07, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'On-Call Incident Triage',
   'Auto-diagnoses production incidents and recommends runbooks, reducing MTTR.',
   'Corporate', 'Technology', 0.29, 0.31, NULL, NULL, 0.07, 0.06, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'AI for Site Reliability Engineering',
   'Predicts service degradation before user impact using telemetry and change signals.',
   'Corporate', 'Technology', 0.26, 0.28, NULL, NULL, 0.06, 0.05, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'Employee Skill Gap Analysis',
   'Maps current workforce skills against future role requirements to prioritize L&D investment.',
   'Corporate', 'HR', 0.22, 0.24, NULL, NULL, 0.05, 0.04, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Generated Training Content',
   'Automatically authors e-learning modules from internal documentation and SME transcripts.',
   'Corporate', 'HR', 0.18, 0.19, NULL, NULL, 0.04, 0.04, 0.32, 0.28, CURRENT_TIMESTAMP()),

  ('YTD', 'Network Intrusion Detection',
   'Deep-packet inspection ML model detecting zero-day threats in network traffic.',
   'Corporate', 'Security', 0.15, 0.16, NULL, NULL, 0.04, 0.04, 0.25, 0.22, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Threat Intelligence Analysis',
   'Ingests threat feeds and correlates with internal logs to prioritize security response.',
   'Corporate', 'Security', 0.11, 0.12, NULL, NULL, 0.03, 0.03, 0.18, 0.16, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Identity Verification AI',
   'Biometric and document-AI pipeline accelerating KYC onboarding while reducing fraud.',
   'Business', 'CX', 0.33, 0.36, NULL, NULL, 0.07, 0.06, 0.50, 0.44, CURRENT_TIMESTAMP());
