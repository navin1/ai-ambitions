# AI Ambitions Dashboard

An executive dashboard for tracking AI investment, ROI, and use case metrics — built with React + FastAPI, deployed on Google Kubernetes Engine.

---

## Architecture

```
                    ┌── /api/* ──→ backend service (NEG) → ai-ambitions-backend pod (FastAPI)
Browser → Compute   │                                              │
  LB (URL map)      │                                     BigQuery (data)
                    │                                     Vertex AI / Gemini (optional)
                    └── /*     ──→ backend bucket → GCS bucket (built React SPA)
```

- **Frontend:** React + TypeScript + Vite, built static and synced to a GCS bucket — no frontend container, served directly by a Compute backend bucket (with Cloud CDN)
- **Backend:** FastAPI (Python 3.12) running in GKE, Playwright for PDF export
- **Routing:** a single manually managed Compute HTTP(S) Load Balancer with a URL map — `/api/*` to the backend's standalone NEG, everything else to the frontend's backend bucket (see `kubernetes/setup-static-frontend-lb.sh`). Not a Kubernetes Ingress — GKE-managed Ingress can't target a GCS bucket.
- **Auth:** ForgeRock Identity Gateway sidecar (prod) / dev-fallback (local)
- **Data:** BigQuery (`ai_ambitions` dataset)
- **Container registry:** Artifact Registry (`us-central1`) — backend image only
- **Cluster:** GKE regional cluster (`us-central1`), Workload Identity
- **CI/CD:** Jenkins builds the backend image (pushed to Artifact Registry) and the frontend build (synced to GCS); ArgoCD syncs `kubernetes/` manifests to the cluster

---

## Prerequisites

| Tool | Install |
|------|---------|
| `gcloud` | https://cloud.google.com/sdk/docs/install |
| `kubectl` | `gcloud components install kubectl` |
| `git` | https://git-scm.com/ |

Authenticate once before running anything:

```bash
gcloud auth login
gcloud auth application-default login   # needed for local dev (BigQuery ADC)
```

---

## One-shot GKE + IAM bootstrap

`deploy-gke.sh` is idempotent — safe to run on a fresh project or re-run for updates. It only provisions infrastructure; it does not build or deploy the app.

```bash
chmod +x deploy-gke.sh
./deploy-gke.sh
```

What it does (in order):

1. Checks `gcloud` and `kubectl` are installed
2. Sets project `mygclearning` and region `us-central1`
3. Enables required GCP APIs (Container, Artifact Registry, IAM, Storage, Compute)
4. Creates Artifact Registry repo `ai-ambitions` (skips if exists)
5. Creates GKE cluster `ai-ambitions-cluster` (skips if exists — takes ~8 min first run)
6. Fetches `kubectl` credentials for the cluster
7. Creates GCP service account `ai-ambitions-app` with BigQuery roles
8. Binds it to the Kubernetes SA via Workload Identity

After it completes:

```bash
kubectl apply -f kubernetes/            # or let ArgoCD sync it — see argocd/application.yaml
./kubernetes/setup-static-frontend-lb.sh  # one-time — GCS bucket + load balancer
```

Then push to git — Jenkins builds the backend image and syncs the frontend build to GCS (see [Redeploying after a code change](#redeploying-after-a-code-change)).

---

## Accessing the application

### Quick access (port-forward, backend only)

```bash
kubectl port-forward svc/ai-ambitions-backend 8000:8000 -n ai-ambitions
```

Then open **http://localhost:8000/docs** to confirm the API is up. There's no frontend pod to port-forward to — for a full local UI check, run the frontend dev server instead (see [Local development](#local-development)) or open the public HTTPS URL once the load balancer is set up.

### Public HTTPS access (production)

`kubernetes/setup-static-frontend-lb.sh` provisions everything needed: the GCS bucket, a Compute backend bucket (with Cloud CDN) for the frontend, a standalone NEG + backend service for the API, a global static IP, a Google-managed SSL certificate, and the URL map tying it together (`/api/*` → backend, everything else → bucket). Review the placeholder `DOMAIN` and `ZONE` values in the script before running it — it's a one-time setup, not idempotent, and creates real billable resources.

```bash
chmod +x kubernetes/setup-static-frontend-lb.sh
./kubernetes/setup-static-frontend-lb.sh
```

Point your DNS `A` record at the IP it prints. The managed certificate finishes provisioning automatically once DNS propagates (can take up to ~60 minutes). The app will be reachable at `https://your-domain.example.com`.

---

## Redeploying after a code change

Push to git — Jenkins (`Jenkinsfile`) builds the backend image and pushes it to Artifact Registry, builds the frontend and syncs `frontend/dist` to the GCS bucket, then updates `kubernetes/deployment-backend.yaml`'s image tag and pushes that back to git. ArgoCD picks up the new tag and rolls out the backend automatically — no manual `kubectl`/`gcloud` commands needed for routine deploys.

To enable the AI chat / NL features (off by default), set `VITE_ENABLE_AI_FEATURES = 'true'` in the `Jenkinsfile` environment block.

---

## Local development

```bash
# 1. Backend
cp .env.example .env
# edit .env — set BIGQUERY_PROJECT_ID, BIGQUERY_DATASET, VERTEX_AI_PROJECT
cd backend
pip install -r requirements.txt
playwright install chromium
uvicorn main:app --reload --port 8000

# 2. Frontend (separate terminal)
cd frontend
npm install
npm run dev          # Vite dev server at http://localhost:5173
```

The Vite dev server proxies `/api/*` to `localhost:8000` automatically (see `vite.config.ts`).

---

## Project layout

```
.
├── backend/                 FastAPI app
│   ├── main.py              App entry point
│   ├── auth.py              ForgeRock IG header auth + BigQuery credentials
│   ├── bigquery_client.py   BigQuery query helpers
│   ├── gemini_client.py     Vertex AI / Gemini client
│   ├── schemas.py           Pydantic request/response models
│   ├── assets/              logo.png, star.png (used in PDF export + favicon)
│   ├── routes/
│   │   ├── overview.py      KPI and investment drill-down endpoints
│   │   ├── query.py         Ad-hoc BigQuery query endpoint
│   │   ├── chat.py          AI chat endpoint (requires Vertex AI)
│   │   └── pdf.py           PDF export via Playwright + Chart.js
│   └── Dockerfile           Backend-only image (FastAPI + Playwright, venv, non-root)
├── frontend/                React app — no Dockerfile; built and synced straight
│   │                        to a GCS bucket, no frontend container at all
│   └── src/
│       ├── App.tsx          Root app, tab routing
│       ├── components/      Header, Charts, DataTable, Chat panel
│       ├── tabs/            OverviewTab and other tab views
│       ├── api/             Typed API clients (overview, query, chat, pdf)
│       └── types/           Shared TypeScript types
├── kubernetes/
│   ├── configmap.yaml             Non-secret env vars (BQ project, Gemini model, etc.)
│   ├── deployment-backend.yaml    Backend deployment (1 replica, health probes, resource limits)
│   ├── service-backend.yaml       ClusterIP service on 8000, standalone NEG annotation
│   ├── service-account.yaml       Kubernetes SA with Workload Identity annotation
│   ├── backend-config.yaml        ForgeRock IG sidecar route config
│   └── setup-static-frontend-lb.sh  One-time: GCS bucket + Compute LB (backend bucket + URL map)
├── bigquery/
│   └── schema.sql           BigQuery dataset + table DDL
├── Jenkinsfile               CI: build+push backend image, build+sync frontend to GCS, update manifest
├── argocd/
│   └── application.yaml     ArgoCD Application — syncs kubernetes/ to the cluster
├── deploy-gke.sh            One-shot GKE cluster + IAM bootstrap script
└── .env.example             Environment variable reference (copy to .env for local dev)
```

---

## Kubernetes manifests reference

| File | Purpose |
|------|---------|
| `configmap.yaml` | Environment config — update `BIGQUERY_PROJECT_ID`, `BIGQUERY_DATASET`, `GEMINI_MODEL` as needed |
| `deployment-backend.yaml` | 1 replica, 512Mi–1Gi RAM, 250m–1 CPU, readiness + liveness probes on `/api/health` |
| `service-backend.yaml` | ClusterIP on 8000; `cloud.google.com/neg` annotation exposes a standalone NEG for the manual load balancer |
| `service-account.yaml` | KSA `ai-ambitions-ksa` annotated for Workload Identity → `ai-ambitions-app` GCP SA |
| `backend-config.yaml` | ForgeRock IG sidecar route config |
| `setup-static-frontend-lb.sh` | One-time script: GCS bucket, backend bucket (+ Cloud CDN), static IP, managed cert, backend service (NEG), URL map, HTTPS proxy — see [Public HTTPS access](#public-https-access-production) |

---

## Troubleshooting

**Backend pod not starting**
```bash
kubectl describe pod -n ai-ambitions -l app=ai-ambitions-backend
kubectl logs -n ai-ambitions -l app=ai-ambitions-backend
```

**PDF export fails**
The container runs Playwright Chromium. Check logs for `BrowserType.launch` errors. `backend/Dockerfile` sets `PLAYWRIGHT_BROWSERS_PATH=/ms-playwright` so Chromium is accessible to the non-root `appuser`.

**BigQuery auth errors**
Ensure the GCP SA `ai-ambitions-app@mygclearning.iam.gserviceaccount.com` has `roles/bigquery.dataViewer` and `roles/bigquery.jobUser`, and that the Workload Identity binding is in place (`deploy-gke.sh` handles this automatically).

**Frontend shows stale content after a deploy**
The bucket sync (`gcloud storage rsync`) updates immediately, but Cloud CDN caches responses. The Jenkins pipeline invalidates the cache (`gcloud compute url-maps invalidate-cdn-cache`) after every sync — if you bypassed Jenkins and uploaded manually, run that command yourself.

**Load balancer / NEG not attaching**
Run `gcloud compute backend-services get-health ai-ambitions-backend-svc --global`. Most common causes: the standalone NEG name in `setup-static-frontend-lb.sh` wasn't updated after `gcloud compute network-endpoint-groups list`, or the backend pods aren't passing the `/api/health` check yet.
