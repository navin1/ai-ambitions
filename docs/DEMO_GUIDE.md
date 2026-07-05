# AI Ambitions Dashboard — Demo Guide

A reference for presenting the app to senior/technical stakeholders. Structured as: what it is, what to show, architecture, and anticipated questions.

---

## 1. What it is (30-second framing)

A use-case and spend management dashboard that gives leadership a single view into AI investment ROI — actuals vs. plan across revenue, NPS, efficiency, and cost KPIs, broken down by category, use case, and vendor. Data is live from BigQuery, not a static export.

An optional AI layer (Gemini via Vertex AI) lets users ask natural-language questions and get back charts/SQL, generated on the fly against the live schema — without needing to know the underlying table structure.

---

## 2. Demo flow (recommended order)

| Step | What you show | What it proves |
|---|---|---|
| 1 | Overview tab loads — 4 KPI tiles (Revenue, NPS, Efficiency, AI Cost) with actual vs. plan, status bands (under/in-band/over) | Real-time financial governance, not a spreadsheet |
| 2 | Switch the period selector (YTD / Q1–Q4) | Data is parameterized and live-queried, not hardcoded per view |
| 3 | Investment breakdown — by category, by use case (ranked), by vendor | Granular spend traceability down to vendor and individual use case |
| 4 | *(if AI features enabled)* Ask the chat panel a natural-language question, e.g. "Show monthly spend split by Capital vs Expense" | NL → SQL → chart generation, grounded in real schema, with follow-up suggested questions |
| 5 | Export to PDF | One-click leadership-ready report generation (headless Chromium rendering) |

If AI features are disabled for this demo (`VITE_ENABLE_AI_FEATURES=false`), skip step 4 and frame it as "available, currently behind a flag while we finalize governance review."

---

## 3. Architecture (one paragraph + diagram)

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   React UI   │──────▶  FastAPI backend  │──────▶│    BigQuery      │
│ (Vite, SPA)  │      │  (Python/uvicorn) │      │  (mygclearning)  │
└─────────────┘      └─────────┬─────────┘      └─────────────────┘
                                │
                      ┌─────────▼─────────┐
                      │  Vertex AI/Gemini  │  (optional, flagged)
                      └───────────────────┘
```

- **Frontend**: React + Vite SPA, built and served as static assets by the same backend container (no separate frontend server).
- **Backend**: FastAPI, single deployable unit, exposes `/api/overview`, `/api/chat`, `/api/query`, `/api/pdf`.
- **Data**: BigQuery, project `mygclearning`, dataset `ai_ambitions`. All reads — no writes from the app.
- **AI layer**: Vertex AI (Gemini 2.5 Flash), initialized lazily on first use — the app runs fine with AI features fully absent, this is not a hard dependency.
- **PDF export**: Server-side headless Chromium (Playwright) renders the dashboard to PDF.

---

## 4. Security & identity model

- **Authentication**: The app renders its own login page (`/login`) and authenticates credentials directly against ForgeRock AM's REST API, setting the resulting AM SSO cookie. ForgeRock Identity Gateway (IG) sits in front of the app in production, validates that cookie on data API requests, and injects identity headers (`x-fr-email`, `x-fr-username`) — the app trusts those headers when present, and independently re-validates the AM cookie itself for `/api/me` (see `kubernetes/backend-config.yaml` for the IG route split between public and SSO-protected paths).
- **GCP access**: Workload Identity in GKE — the app's Kubernetes service account is bound to a GCP service account scoped to `BigQuery Data Viewer` + `BigQuery Job User` (+ `Vertex AI User` if AI features are enabled). No service account keys are stored anywhere in the cluster or image.
- **No credentials in the container image** — auth is resolved at runtime via the cluster's identity, not baked-in secrets.

---

## 5. Deployment & delivery pipeline

- **Containerized**: single multi-stage Dockerfile (Node build stage → Python/FastAPI runtime stage), ~2.4GB due to bundled headless Chromium for PDF export.
- **CI**: Jenkins builds the image, pushes to Artifact Registry (Workload Identity, no key files), and updates the deployment manifest's image tag in git.
- **CD**: ArgoCD watches the `kubernetes/` manifests in this repo and auto-syncs the cluster to match git — a GitOps pull model, not a push-based deploy. Cluster state always matches what's committed; manual `kubectl` drift gets self-healed.
- **Runtime**: GKE, namespace `ai-ambitions`, autoscaling-ready resource requests/limits (512Mi/250m request, 1Gi/1000m limit per pod).

---

## 6. Anticipated questions

**"Is this data real or sample data?"**
Live BigQuery queries against `mygclearning.ai_ambitions` — same data warehouse used elsewhere, not a mock/demo dataset (unless explicitly noted that current figures are placeholder/test rows).

**"What happens if Vertex AI / Gemini is down?"**
The chat/NL features degrade gracefully — overview KPIs and investment breakdowns have no dependency on Vertex AI at all. Only the chat panel and PDF AI-narrative text would be affected.

**"How do you control who sees this data?"**
The SPA shell and login page are public; every data API (`/api/overview`, `/api/query`, `/api/chat`, `/api/pdf`) is gated by ForgeRock IG/AM at the network edge — only requests carrying a validated AM session reach them. On top of that, the app resolves an `admin`/`user` role from AD group membership (via AM's `memberOf` session attribute, configured through `FORGEROCK_ADMIN_GROUP`) and exposes it through `/api/me` and a `require_role()` FastAPI dependency — currently surfaced as a badge in the header, not yet gating any specific feature since no admin-only capability has been defined. The app itself does no row-level data filtering currently.

**"What's the cost of running this?"**
Primary costs: BigQuery query bytes scanned, GKE node compute, and (if enabled) Gemini token usage via Vertex AI. The "AI Cost" KPI tile on the dashboard itself is tracking this category.

**"Can this scale to more use cases / more data sources?"**
Yes — the schema-context builder in the backend introspects BigQuery table schema dynamically, and the chart-rendering layer is generic (bar/line/donut/kpi/table/etc.), so adding tables or KPIs is additive, not a rewrite.

**"How fast is it?"**
Overview responses are cached server-side for 30 seconds to absorb repeated loads; BigQuery itself returns most aggregate queries in low single-digit seconds given the dataset size.

---

## 7. Known current limitations (be upfront about these if asked)

- Single environment configuration shown today — multi-tenant is not implemented. AD-group role resolution (admin/user) exists but isn't gating any feature yet; `FORGEROCK_ADMIN_GROUP` is unset until the AD group is created.
- AI features are feature-flagged off by default pending governance/cost review.
- Only one dashboard tab (Overview) currently built; chat-driven ad-hoc charts are the extensibility path for additional views.
