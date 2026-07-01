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
-- 100 use cases: each contributes to at least one of (revenue, nps, efficiency).
-- No use case contributes to all three.
-- current_phase: Planning | Pilot | Scaling | Production
-- revenue_actual_dollars = revenue_actual × 20  ($M, assuming ~$2B revenue base)
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. KPI Summary ────────────────────────────────────────────────────────────

INSERT INTO `ai_ambitions.ai_amb_kpi_summary`
  (period, kpi_id, actual_value, plan_value, actual_delta, delta_label,
   range_min, range_max, target_min, target_max, update_ts)
VALUES
  ('YTD', 'ai-cost',     38.5, 42.0, -3.5, 'vs plan',  0,  60,   NULL, 45,   CURRENT_TIMESTAMP()),
  ('YTD', 'revenue',      2.1,  4.5,  0.3, 'vs Q4',    0,  10,   3,    7,    CURRENT_TIMESTAMP()),
  ('YTD', 'nps',          3.4,  3.0,  0.5, 'vs Q4',    0,   6,   2,    4,    CURRENT_TIMESTAMP()),
  ('YTD', 'efficiency',  36.0, 32.0,  4.0, 'vs Q4',    0,  50,  30,   40,   CURRENT_TIMESTAMP());


-- ── 2. Use Case Data — YTD ───────────────────────────────────────────────────
-- revenue_actual_dollars = revenue_actual × 20 ($M, ~$2B revenue base)
-- revenue_plan_dollars   = revenue_plan   × 20

INSERT INTO `ai_ambitions.ai_amb_use_case_data`
  (period, use_case, description, csg, functional_area, current_phase,
   cost_actual, cost_plan,
   revenue_actual, revenue_plan, revenue_actual_dollars, revenue_plan_dollars,
   nps_actual,     nps_plan,
   efficiency_actual, efficiency_plan,
   update_ts)
VALUES

  -- ── Group A: Infrastructure — efficiency only (20 use cases) ─────────────

  ('YTD', 'AI Infrastructure Foundation',
   'Core AI compute, networking and storage platform underpinning all AI initiatives.',
   'Corporate', 'Technology', 'Production',
   1.60, 1.73, NULL, NULL, NULL, NULL, NULL, NULL, 0.80, 0.70, CURRENT_TIMESTAMP()),

  ('YTD', 'MLOps Platform & Tooling',
   'Automated pipelines for model training, deployment and monitoring at scale.',
   'Corporate', 'Technology', 'Production',
   1.30, 1.40, NULL, NULL, NULL, NULL, NULL, NULL, 1.20, 1.06, CURRENT_TIMESTAMP()),

  ('YTD', 'Data Labeling & Annotation Pipeline',
   'High-quality labeled data production for supervised learning across all domains.',
   'Corporate', 'Technology', 'Production',
   1.10, 1.19, NULL, NULL, NULL, NULL, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'Foundation Model API Gateway',
   'Centralized proxy for managing, routing and rate-limiting foundation model API calls.',
   'Corporate', 'Technology', 'Scaling',
   0.90, 0.97, NULL, NULL, NULL, NULL, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Security & Compliance Framework',
   'Security controls, audit logging and compliance tooling for all AI workloads.',
   'Corporate', 'Security', 'Production',
   0.65, 0.70, NULL, NULL, NULL, NULL, NULL, NULL, 0.25, 0.22, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Experimentation Platform',
   'Managed sandbox for rapid hypothesis testing and model prototyping by data scientists.',
   'Corporate', 'Technology', 'Production',
   0.60, 0.65, NULL, NULL, NULL, NULL, NULL, NULL, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'Feature Store Implementation',
   'Centralized repository for storing, versioning and serving ML features in real time.',
   'Corporate', 'Technology', 'Scaling',
   0.50, 0.54, NULL, NULL, NULL, NULL, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'Model Registry & Versioning',
   'Catalog tracking all trained models, their lineage, hyperparameters and promotion status.',
   'Corporate', 'Technology', 'Scaling',
   0.45, 0.49, NULL, NULL, NULL, NULL, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Observability & Monitoring',
   'Dashboard and alerting layer for model performance drift and data quality degradation.',
   'Corporate', 'Technology', 'Pilot',
   0.38, 0.41, NULL, NULL, NULL, NULL, NULL, NULL, 0.45, 0.40, CURRENT_TIMESTAMP()),

  ('YTD', 'Vector Database Infrastructure',
   'Low-latency vector similarity search layer powering semantic search and RAG pipelines.',
   'Corporate', 'Technology', 'Scaling',
   0.36, 0.39, NULL, NULL, NULL, NULL, NULL, NULL, 0.55, 0.48, CURRENT_TIMESTAMP()),

  ('YTD', 'GPU Cluster Management',
   'Scheduling, autoscaling and cost allocation for shared GPU compute across teams.',
   'Corporate', 'Technology', 'Production',
   0.30, 0.32, NULL, NULL, NULL, NULL, NULL, NULL, 0.90, 0.79, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Model Governance Tooling',
   'Policy enforcement, explainability reports and bias assessments for deployed models.',
   'Corporate', 'Security', 'Pilot',
   0.28, 0.30, NULL, NULL, NULL, NULL, NULL, NULL, 0.20, 0.18, CURRENT_TIMESTAMP()),

  ('YTD', 'Synthetic Data Generation Platform',
   'Generates privacy-safe synthetic datasets to augment scarce training data.',
   'Corporate', 'Technology', 'Pilot',
   0.22, 0.24, NULL, NULL, NULL, NULL, NULL, NULL, 0.35, 0.31, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Center of Excellence',
   'Cross-functional team setting AI strategy, standards and best practices company-wide.',
   'Corporate', 'HR', 'Production',
   0.20, 0.22, NULL, NULL, NULL, NULL, NULL, NULL, 0.30, 0.26, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Ethics & Bias Testing Framework',
   'Systematic testing suite that surfaces fairness and bias issues before model deployment.',
   'Corporate', 'Security', 'Pilot',
   0.18, 0.19, NULL, NULL, NULL, NULL, NULL, NULL, 0.15, 0.13, CURRENT_TIMESTAMP()),

  ('YTD', 'Prompt Engineering Tooling',
   'IDE and version-control tooling for authoring, testing and deploying LLM prompt templates.',
   'Corporate', 'Technology', 'Pilot',
   0.15, 0.16, NULL, NULL, NULL, NULL, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Documentation Hub',
   'Centralized knowledge base for AI runbooks, architecture diagrams and onboarding guides.',
   'Corporate', 'Technology', 'Production',
   0.12, 0.13, NULL, NULL, NULL, NULL, NULL, NULL, 0.20, 0.18, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Vendor Management System',
   'Tracks AI vendor contracts, SLAs, pricing tiers and renewal calendars.',
   'Corporate', 'Operations', 'Production',
   0.11, 0.12, NULL, NULL, NULL, NULL, NULL, NULL, 0.25, 0.22, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Benchmark Testing Suite',
   'Automated benchmark harness measuring model accuracy, latency and cost regressions.',
   'Corporate', 'Technology', 'Scaling',
   0.08, 0.09, NULL, NULL, NULL, NULL, NULL, NULL, 0.30, 0.26, CURRENT_TIMESTAMP()),

  ('YTD', 'Data Platform Modernization',
   'Migration of legacy data pipelines to modern lakehouse architecture enabling AI workloads.',
   'Corporate', 'Technology', 'Scaling',
   0.08, 0.09, NULL, NULL, NULL, NULL, NULL, NULL, 0.85, 0.75, CURRENT_TIMESTAMP()),

  -- ── Group B: Revenue only (15 use cases) ─────────────────────────────────
  -- revenue_actual_dollars = revenue_actual × 20

  ('YTD', 'Personalized Search & Discovery',
   'Semantic search and personalized result ranking to increase conversion from site search.',
   'Consumer', 'Commerce', 'Production',
   1.30, 1.40, 0.25, 0.29, 5.0, 5.8, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Pricing Engine',
   'Real-time demand-aware pricing model that maximizes revenue per unit.',
   'Consumer', 'Commerce', 'Production',
   1.00, 1.08, 0.20, 0.23, 4.0, 4.6, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Market Basket Analysis',
   'Identifies co-purchase patterns to drive bundled promotions and cross-category revenue.',
   'Consumer', 'Commerce', 'Scaling',
   0.80, 0.86, 0.16, 0.18, 3.2, 3.6, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Product Recommendation API',
   'Collaborative-filtering API serving personalized product recommendations across all channels.',
   'Consumer', 'Commerce', 'Production',
   0.65, 0.70, 0.13, 0.15, 2.6, 3.0, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Markdown Optimization',
   'ML model scheduling optimal discount timing and depth to maximize margin recovery.',
   'Business', 'Finance', 'Scaling',
   0.58, 0.63, 0.11, 0.13, 2.2, 2.6, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Next Best Action for Sales',
   'Recommends the highest-probability-to-close action for each sales opportunity in CRM.',
   'Business', 'Commerce', 'Scaling',
   0.52, 0.56, 0.10, 0.12, 2.0, 2.4, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Marketing Mix Modeling',
   'Attribution model allocating revenue credit across channels to optimize marketing spend.',
   'Consumer', 'Marketing', 'Pilot',
   0.44, 0.48, 0.08, 0.09, 1.6, 1.8, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Lead Scoring Model',
   'Predicts likelihood of B2B lead conversion, prioritizing sales outreach.',
   'Business', 'Commerce', 'Scaling',
   0.36, 0.39, 0.07, 0.08, 1.4, 1.6, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Competitor Price Monitoring',
   'Scrapes and tracks competitor pricing, feeding real-time signals to the pricing engine.',
   'Consumer', 'Commerce', 'Production',
   0.30, 0.32, 0.05, 0.06, 1.0, 1.2, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Ad Creative Generation',
   'Generative AI producing ad copy and creative variants for A/B testing at scale.',
   'Consumer', 'Marketing', 'Pilot',
   0.28, 0.30, 0.05, 0.06, 1.0, 1.2, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Email Campaigns',
   'Sends individually tailored offers and content based on customer purchase history.',
   'Consumer', 'Marketing', 'Production',
   0.25, 0.27, 0.04, 0.05, 0.8, 1.0, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Assisted Sales Forecasting',
   'Improves quarterly revenue forecast accuracy using ML on pipeline and external signals.',
   'Business', 'Finance', 'Scaling',
   0.22, 0.24, 0.04, 0.05, 0.8, 1.0, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Subscription Propensity Modeling',
   'Predicts which customers are most likely to upgrade to premium plans.',
   'Consumer', 'Marketing', 'Pilot',
   0.22, 0.24, 0.04, 0.05, 0.8, 1.0, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Website Personalization Engine',
   'Dynamically adapts homepage banners and product carousels per visitor segment.',
   'Consumer', 'Commerce', 'Scaling',
   0.18, 0.19, 0.03, 0.03, 0.6, 0.6, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Store Layout Optimization',
   'Recommends shelf and end-cap placements to maximize in-store purchase probability.',
   'Consumer', 'Operations', 'Pilot',
   0.14, 0.15, 0.02, 0.02, 0.4, 0.4, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group C: NPS only (15 use cases) ─────────────────────────────────────

  ('YTD', 'Conversational Returns Assistant',
   'AI chatbot guiding customers through returns, reducing handling time and friction.',
   'Consumer', 'CX', 'Production',
   1.20, 1.30, NULL, NULL, NULL, NULL, 0.38, 0.33, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Chat Triage & Routing',
   'Classifies incoming chat intents and routes to the best-available agent or bot.',
   'Consumer', 'CX', 'Production',
   0.88, 0.95, NULL, NULL, NULL, NULL, 0.28, 0.25, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Contact Center Quality Assurance',
   'Auto-scores 100% of agent interactions against quality rubrics, replacing sampling.',
   'Consumer', 'CX', 'Scaling',
   0.66, 0.71, NULL, NULL, NULL, NULL, 0.22, 0.19, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Voice of the Customer Analytics',
   'Synthesizes NPS verbatims, reviews and social mentions into weekly action themes.',
   'Consumer', 'CX', 'Production',
   0.52, 0.56, NULL, NULL, NULL, NULL, 0.17, 0.15, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Sentiment Analysis on Reviews',
   'Real-time classification of product and service reviews by sentiment and topic.',
   'Consumer', 'CX', 'Production',
   0.44, 0.48, NULL, NULL, NULL, NULL, 0.14, 0.12, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Real-time Language Translation',
   'Enables multilingual support conversations without requiring specialist agents.',
   'Consumer', 'CX', 'Scaling',
   0.36, 0.39, NULL, NULL, NULL, NULL, 0.11, 0.10, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Service Bot Escalation',
   'Detects customer frustration signals and escalates to human agents at the right moment.',
   'Consumer', 'CX', 'Scaling',
   0.33, 0.36, NULL, NULL, NULL, NULL, 0.10, 0.09, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Loyalty Program Rewards',
   'Tailors reward offers to individual redemption likelihood to boost program engagement.',
   'Consumer', 'Marketing', 'Pilot',
   0.30, 0.32, NULL, NULL, NULL, NULL, 0.09, 0.08, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Voice-based In-store Assistant',
   'Ambient voice assistant in stores answering product, price and location queries.',
   'Consumer', 'CX', 'Pilot',
   0.26, 0.28, NULL, NULL, NULL, NULL, 0.07, 0.06, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Accessibility Issue Detection',
   'Automated scanner identifying WCAG accessibility failures across digital products.',
   'Corporate', 'Technology', 'Pilot',
   0.22, 0.24, NULL, NULL, NULL, NULL, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Call Center Transcription & Analysis',
   'Transcribes calls in real time, surfacing insights for agent coaching and compliance.',
   'Consumer', 'CX', 'Scaling',
   0.22, 0.24, NULL, NULL, NULL, NULL, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Social Media Content Moderation',
   'Classifies and prioritizes policy violations in user-generated social content.',
   'Consumer', 'Marketing', 'Production',
   0.18, 0.19, NULL, NULL, NULL, NULL, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Employee Survey Analysis',
   'NLP analysis of employee engagement surveys, surfacing key themes for HR action.',
   'Corporate', 'HR', 'Pilot',
   0.15, 0.16, NULL, NULL, NULL, NULL, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Feedback Topic Modeling',
   'Clusters open-ended feedback into actionable topics by product or journey stage.',
   'Consumer', 'CX', 'Scaling',
   0.15, 0.16, NULL, NULL, NULL, NULL, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Financial Advice Bot',
   'Conversational assistant providing tailored financial product recommendations.',
   'Business', 'CX', 'Planning',
   0.11, 0.12, NULL, NULL, NULL, NULL, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group D: Efficiency only (15 use cases) ───────────────────────────────

  ('YTD', 'Demand Forecast v3',
   'Next-generation demand signal model combining internal sell-through with external macro signals.',
   'Business', 'Operations', 'Production',
   1.02, 1.10, NULL, NULL, NULL, NULL, NULL, NULL, 3.80, 3.34, CURRENT_TIMESTAMP()),

  ('YTD', 'Warehouse Slotting AI',
   'Optimizes pick-path layout in fulfillment centers to minimize travel time.',
   'Business', 'Operations', 'Production',
   0.88, 0.95, NULL, NULL, NULL, NULL, NULL, NULL, 3.20, 2.82, CURRENT_TIMESTAMP()),

  ('YTD', 'Logistics Route Optimization',
   'Dynamic last-mile routing that reduces fuel cost and delivery time simultaneously.',
   'Business', 'Operations', 'Production',
   0.66, 0.71, NULL, NULL, NULL, NULL, NULL, NULL, 2.80, 2.46, CURRENT_TIMESTAMP()),

  ('YTD', 'Fraud Detection Engine',
   'Real-time transaction scoring model reducing fraud losses while minimizing false declines.',
   'Corporate', 'Finance', 'Production',
   0.51, 0.55, NULL, NULL, NULL, NULL, NULL, NULL, 2.20, 1.94, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Document Processing',
   'IDP pipeline extracting structured data from invoices, contracts and forms at scale.',
   'Corporate', 'Operations', 'Scaling',
   0.44, 0.48, NULL, NULL, NULL, NULL, NULL, NULL, 1.80, 1.58, CURRENT_TIMESTAMP()),

  ('YTD', 'HR Candidate Screening',
   'Anonymized CV ranking model reducing time-to-shortlist for high-volume roles.',
   'Corporate', 'HR', 'Scaling',
   0.36, 0.39, NULL, NULL, NULL, NULL, NULL, NULL, 1.50, 1.32, CURRENT_TIMESTAMP()),

  ('YTD', 'Energy Consumption Forecasting',
   '24-hour load forecast model enabling smarter energy procurement and grid management.',
   'Corporate', 'Operations', 'Scaling',
   0.33, 0.36, NULL, NULL, NULL, NULL, NULL, NULL, 1.30, 1.14, CURRENT_TIMESTAMP()),

  ('YTD', 'Code Co-pilot & Review Assistant',
   'In-IDE LLM assistant accelerating developer velocity and catching code issues early.',
   'Corporate', 'Technology', 'Production',
   0.29, 0.31, NULL, NULL, NULL, NULL, NULL, NULL, 1.10, 0.97, CURRENT_TIMESTAMP()),

  ('YTD', 'A/B Test Analysis Automation',
   'Automated Bayesian experiment analyzer that eliminates manual stats review delays.',
   'Consumer', 'Marketing', 'Scaling',
   0.26, 0.28, NULL, NULL, NULL, NULL, NULL, NULL, 0.90, 0.79, CURRENT_TIMESTAMP()),

  ('YTD', 'Procurement Spend Analytics',
   'Classifies and benchmarks spend to surface consolidation and renegotiation opportunities.',
   'Corporate', 'Finance', 'Pilot',
   0.22, 0.24, NULL, NULL, NULL, NULL, NULL, NULL, 0.80, 0.70, CURRENT_TIMESTAMP()),

  ('YTD', 'Predictive Maintenance for Fleet',
   'Anomaly detection on vehicle telematics data to prevent unplanned downtime.',
   'Business', 'Operations', 'Pilot',
   0.22, 0.24, NULL, NULL, NULL, NULL, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'Financial Anomaly Detection',
   'Flags unusual GL transactions for finance review, reducing month-end close time.',
   'Corporate', 'Finance', 'Scaling',
   0.18, 0.19, NULL, NULL, NULL, NULL, NULL, NULL, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'Cloud Cost Optimization AI',
   'Continuously right-sizes cloud resources and identifies idle or over-provisioned assets.',
   'Corporate', 'Technology', 'Pilot',
   0.15, 0.16, NULL, NULL, NULL, NULL, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'IT Helpdesk Ticket Automation',
   'Auto-classifies, prioritizes and resolves Tier-1 IT tickets without human involvement.',
   'Corporate', 'Technology', 'Scaling',
   0.15, 0.16, NULL, NULL, NULL, NULL, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'Legal Contract Review AI',
   'Extracts obligations and flags non-standard clauses in contracts for legal review.',
   'Corporate', 'Operations', 'Pilot',
   0.11, 0.12, NULL, NULL, NULL, NULL, NULL, NULL, 0.30, 0.26, CURRENT_TIMESTAMP()),

  -- ── Group E: Revenue + NPS (12 use cases) ────────────────────────────────

  ('YTD', 'Visual Search for Products',
   'Lets customers search by image, increasing discovery and conversion for hard-to-describe items.',
   'Consumer', 'Commerce', 'Production',
   0.66, 0.71, 0.09, 0.10, 1.8, 2.0, 0.12, 0.11, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized In-App Notifications',
   'Sends contextually relevant push notifications based on real-time behavior signals.',
   'Consumer', 'Marketing', 'Production',
   0.51, 0.55, 0.07, 0.08, 1.4, 1.6, 0.09, 0.08, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Social Media Trend Identification',
   'Detects emerging trends from social data to inform content and product decisions.',
   'Consumer', 'Marketing', 'Scaling',
   0.37, 0.40, 0.05, 0.06, 1.0, 1.2, 0.07, 0.06, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Ad Targeting',
   'Real-time audience targeting model optimizing ad spend allocation across digital channels.',
   'Consumer', 'Marketing', 'Scaling',
   0.33, 0.36, 0.05, 0.06, 1.0, 1.2, 0.06, 0.05, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Marketing Offer Generation',
   'Creates individualized promotional offers predicted to drive highest incremental revenue.',
   'Consumer', 'Marketing', 'Pilot',
   0.29, 0.31, 0.04, 0.05, 0.8, 1.0, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Upsell/Cross-sell Recommendation Engine',
   'Surfaces next-best-product recommendations at checkout to increase basket size.',
   'Consumer', 'Commerce', 'Production',
   0.29, 0.31, 0.04, 0.05, 0.8, 1.0, 0.05, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Content Feed',
   'Ranks editorial and product content per user to maximize engagement and session depth.',
   'Consumer', 'Commerce', 'Scaling',
   0.26, 0.28, 0.03, 0.03, 0.6, 0.6, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Powered Merchandising Allocation',
   'Optimizes inventory allocation across channels and geographies to reduce stockouts.',
   'Business', 'Commerce', 'Scaling',
   0.22, 0.24, 0.03, 0.03, 0.6, 0.6, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Ad Copy Performance Testing',
   'Runs multivariate ad copy experiments and auto-promotes best-performing variants.',
   'Consumer', 'Marketing', 'Pilot',
   0.18, 0.19, 0.02, 0.02, 0.4, 0.4, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Journey Orchestration',
   'Coordinates cross-channel outreach timing and content to guide customers toward purchase.',
   'Consumer', 'CX', 'Pilot',
   0.15, 0.16, 0.02, 0.02, 0.4, 0.4, 0.03, 0.03, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Dynamic Customer Offer Engine',
   'Real-time offer engine personalizing promotions at every digital touchpoint.',
   'Consumer', 'Marketing', 'Production',
   0.44, 0.48, 0.06, 0.07, 1.2, 1.4, 0.08, 0.07, NULL, NULL, CURRENT_TIMESTAMP()),

  ('YTD', 'Omnichannel AI Orchestration Platform',
   'Master AI layer coordinating personalization signals across web, app and in-store.',
   'Consumer', 'Technology', 'Planning',
   0.18, 0.19, 0.03, 0.03, 0.6, 0.6, 0.04, 0.04, NULL, NULL, CURRENT_TIMESTAMP()),

  -- ── Group F: Revenue + Efficiency (12 use cases) ─────────────────────────

  ('YTD', 'Supply Chain Anomaly Detection',
   'Identifies disruption signals early, enabling proactive mitigation of supply shortfalls.',
   'Business', 'Operations', 'Scaling',
   0.51, 0.55, 0.06, 0.07, 1.2, 1.4, NULL, NULL, 1.00, 0.88, CURRENT_TIMESTAMP()),

  ('YTD', 'Product Defect Detection',
   'Computer-vision inspection model on the production line, reducing defect escape rate.',
   'Business', 'Operations', 'Production',
   0.40, 0.43, 0.05, 0.06, 1.0, 1.2, NULL, NULL, 0.80, 0.70, CURRENT_TIMESTAMP()),

  ('YTD', 'Marketing Campaign Lookalike Modeling',
   'Builds high-value audience lookalikes from first-party data for paid media.',
   'Consumer', 'Marketing', 'Scaling',
   0.37, 0.40, 0.04, 0.05, 0.8, 1.0, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Lifetime Value Prediction',
   'Scores each customer predicted LTV to prioritize retention and acquisition spend.',
   'Consumer', 'Finance', 'Scaling',
   0.33, 0.36, 0.04, 0.05, 0.8, 1.0, NULL, NULL, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Ad Content Optimization',
   'Real-time creative optimization adjusting ad content elements to maximize CTR.',
   'Consumer', 'Marketing', 'Pilot',
   0.29, 0.31, 0.03, 0.03, 0.6, 0.6, NULL, NULL, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Powered Inventory Allocation',
   'Distributes available inventory across fulfillment nodes to minimize split shipments.',
   'Business', 'Operations', 'Scaling',
   0.26, 0.28, 0.03, 0.03, 0.6, 0.6, NULL, NULL, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'Price Elasticity Modeling',
   'Quantifies demand sensitivity to price changes to inform optimal price-setting strategy.',
   'Business', 'Finance', 'Pilot',
   0.22, 0.24, 0.02, 0.02, 0.4, 0.4, NULL, NULL, 0.35, 0.31, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Invoice Reconciliation',
   'Matches purchase orders, delivery receipts and invoices to resolve discrepancies automatically.',
   'Corporate', 'Finance', 'Production',
   0.18, 0.19, 0.02, 0.02, 0.4, 0.4, NULL, NULL, 0.28, 0.25, CURRENT_TIMESTAMP()),

  ('YTD', 'Predictive Cash Flow Forecasting',
   '90-day cash flow forecast model improving treasury planning accuracy.',
   'Corporate', 'Finance', 'Pilot',
   0.15, 0.16, 0.02, 0.02, 0.4, 0.4, NULL, NULL, 0.22, 0.19, CURRENT_TIMESTAMP()),

  ('YTD', 'Workforce Demand Planning AI',
   'Forecasts staffing demand by role and region, reducing over- and under-hiring.',
   'Corporate', 'HR', 'Pilot',
   0.11, 0.12, 0.01, 0.01, 0.2, 0.2, NULL, NULL, 0.15, 0.13, CURRENT_TIMESTAMP()),

  ('YTD', 'Personalized Search & Recommendation Hub',
   'Unified platform combining semantic search and collaborative filtering across all properties.',
   'Consumer', 'Commerce', 'Production',
   0.59, 0.64, 0.08, 0.09, 1.6, 1.8, NULL, NULL, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'AI Contract Lifecycle Management',
   'End-to-end AI platform automating contract drafting, review, approval and renewal.',
   'Corporate', 'Operations', 'Pilot',
   0.26, 0.28, 0.04, 0.05, 0.8, 1.0, NULL, NULL, 0.35, 0.31, CURRENT_TIMESTAMP()),

  -- ── Group G: NPS + Efficiency (11 use cases) ─────────────────────────────

  ('YTD', 'Customer Service Agent Assist',
   'Real-time knowledge panel surfacing answers and next-best-actions for live agents.',
   'Consumer', 'CX', 'Production',
   0.59, 0.64, NULL, NULL, NULL, NULL, 0.18, 0.16, 1.40, 1.23, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Knowledge Base Writer',
   'Generates and updates help-center articles from resolved ticket transcripts.',
   'Consumer', 'CX', 'Scaling',
   0.44, 0.48, NULL, NULL, NULL, NULL, 0.14, 0.12, 1.10, 0.97, CURRENT_TIMESTAMP()),

  ('YTD', 'IT Service Management Automation',
   'AI-driven ITSM that auto-resolves incidents, changes and problems from pattern history.',
   'Corporate', 'Technology', 'Scaling',
   0.37, 0.40, NULL, NULL, NULL, NULL, 0.10, 0.09, 0.90, 0.79, CURRENT_TIMESTAMP()),

  ('YTD', 'Smart Building Energy Management',
   'Adjusts HVAC and lighting dynamically to minimize energy use while maintaining comfort.',
   'Corporate', 'Operations', 'Pilot',
   0.29, 0.31, NULL, NULL, NULL, NULL, 0.08, 0.07, 0.70, 0.62, CURRENT_TIMESTAMP()),

  ('YTD', 'On-Call Incident Triage',
   'Auto-diagnoses production incidents and recommends runbooks, reducing MTTR.',
   'Corporate', 'Technology', 'Scaling',
   0.29, 0.31, NULL, NULL, NULL, NULL, 0.07, 0.06, 0.60, 0.53, CURRENT_TIMESTAMP()),

  ('YTD', 'AI for Site Reliability Engineering',
   'Predicts service degradation before user impact using telemetry and change signals.',
   'Corporate', 'Technology', 'Pilot',
   0.26, 0.28, NULL, NULL, NULL, NULL, 0.06, 0.05, 0.50, 0.44, CURRENT_TIMESTAMP()),

  ('YTD', 'Employee Skill Gap Analysis',
   'Maps current workforce skills against future role requirements to prioritize L&D investment.',
   'Corporate', 'HR', 'Pilot',
   0.22, 0.24, NULL, NULL, NULL, NULL, 0.05, 0.04, 0.40, 0.35, CURRENT_TIMESTAMP()),

  ('YTD', 'AI-Generated Training Content',
   'Automatically authors e-learning modules from internal documentation and SME transcripts.',
   'Corporate', 'HR', 'Planning',
   0.18, 0.19, NULL, NULL, NULL, NULL, 0.04, 0.04, 0.32, 0.28, CURRENT_TIMESTAMP()),

  ('YTD', 'Network Intrusion Detection',
   'Deep-packet inspection ML model detecting zero-day threats in network traffic.',
   'Corporate', 'Security', 'Production',
   0.15, 0.16, NULL, NULL, NULL, NULL, 0.04, 0.04, 0.25, 0.22, CURRENT_TIMESTAMP()),

  ('YTD', 'Automated Threat Intelligence Analysis',
   'Ingests threat feeds and correlates with internal logs to prioritize security response.',
   'Corporate', 'Security', 'Pilot',
   0.11, 0.12, NULL, NULL, NULL, NULL, 0.03, 0.03, 0.18, 0.16, CURRENT_TIMESTAMP()),

  ('YTD', 'Customer Identity Verification AI',
   'Biometric and document-AI pipeline accelerating KYC onboarding while reducing fraud.',
   'Business', 'CX', 'Production',
   0.33, 0.36, NULL, NULL, NULL, NULL, 0.07, 0.06, 0.50, 0.44, CURRENT_TIMESTAMP());


-- ── 3. Sample notes — for testing the KPI capsule note popover ───────────────
-- One representative use case per KPI group so all three note types are tested.

-- Revenue-only use case: one clickable capsule (REVENUE)
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET revenue_notes = 'YTD search conversion lifted 2.8pp after semantic ranking rollout. Q3 A/B test (n=2.1M sessions) confirmed; now in full production across all markets.'
WHERE period = 'YTD' AND use_case = 'Personalized Search & Discovery';

-- NPS-only use case: one clickable capsule (NPS)
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET nps_notes = 'Return resolution time dropped from 4.2 to 1.8 days post-launch. Friction reduction confirmed in exit surveys; correlates with +0.38 NPS pts improvement.'
WHERE period = 'YTD' AND use_case = 'Conversational Returns Assistant';

-- Efficiency-only use case: one clickable capsule (EFFICIENCY)
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET efficiency_notes = 'Forecast MAPE improved from 22% to 9% on a 4-week horizon. Inventory holding cost down $1.2M annualized versus prior model baseline.'
WHERE period = 'YTD' AND use_case = 'Demand Forecast v3';

-- Revenue + NPS use case: two clickable capsules
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET revenue_notes = 'Image-to-product match rate at 87%. Holdout analysis confirms 1.9× higher conversion for visual-search sessions vs standard search.',
    nps_notes     = 'Reduced "can\'t find it" CX contacts by 22%. Customers rate discovery experience 4.3/5 vs 3.7/5 prior to rollout.'
WHERE period = 'YTD' AND use_case = 'Visual Search for Products';

-- Revenue + Efficiency use case: two clickable capsules
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET revenue_notes    = 'Early disruption detection enabled proactive rerouting; stockout rate fell 18pp in pilot DCs, recovering an estimated $1.2M revenue.',
    efficiency_notes = 'Alert-to-resolution time cut from 6.1 to 2.4 hours. Analyst workload reduced by ~30% through automated root-cause triaging.'
WHERE period = 'YTD' AND use_case = 'Supply Chain Anomaly Detection';

-- NPS + Efficiency use case: two clickable capsules
UPDATE `ai_ambitions.ai_amb_use_case_data`
SET nps_notes        = 'First-contact resolution rate rose from 71% to 84% in agent-handled contacts, directly correlating with +0.18 NPS pts uplift.',
    efficiency_notes = 'Average handle time down 38s per contact (~15%). At current volume this frees ~4,200 agent-hours per month.'
WHERE period = 'YTD' AND use_case = 'Customer Service Agent Assist';
