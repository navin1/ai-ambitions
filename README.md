# AI Ambitions Dashboard

An executive dashboard for tracking AI investment, ROI, and use case metrics — built with React + FastAPI, deployed on Google Kubernetes Engine.

---

## Architecture

```
                  ┌── /api/* ──→ ai-ambitions-backend Service ──→ backend pods (FastAPI)
Browser → GKE     │                                                     │
  Ingress         │                                            BigQuery (data)
                  │                                            Vertex AI / Gemini (optional)
                  └── /*     ──→ ai-ambitions-frontend Service ──→ frontend pods (nginx + React SPA)
```

- **Frontend:** React + TypeScript + Vite, built and served as static files by nginx (non-root, `nginxinc/nginx-unprivileged`)
- **Backend:** FastAPI (Python 3.12) running in GKE, Playwright for PDF export
- **Routing:** a single GKE-managed Ingress with path-based rules — `/api/*` to the backend Service, everything else to the frontend Service. Both sit behind the same host/IP, so the frontend's relative-path API calls (`baseURL: '/api'`) work unchanged with no CORS configuration needed.
- **Auth:** ForgeRock Identity Gateway sidecar (prod) / dev-fallback (local)
- **Data:** BigQuery (`ai_ambitions` dataset)
- **Container registry:** Artifact Registry (`us-central1`) — separate backend and frontend images
- **Cluster:** GKE regional cluster (`us-central1`), Workload Identity
- **CI/CD:** Jenkins builds and pushes both images to Artifact Registry; ArgoCD syncs `kubernetes/` manifests to the cluster

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
3. Enables required GCP APIs (Container, Artifact Registry, IAM, Compute)
4. Creates Artifact Registry repo `ai-ambitions` (skips if exists)
5. Creates GKE cluster `ai-ambitions-cluster` (skips if exists — takes ~8 min first run)
6. Fetches `kubectl` credentials for the cluster
7. Creates GCP service account `ai-ambitions-app` with BigQuery roles
8. Binds it to the Kubernetes SA via Workload Identity

After it completes:

```bash
kubectl apply -f kubernetes/   # or let ArgoCD sync it — see argocd/application.yaml
```

Then push to git — Jenkins builds and pushes both images (see [Redeploying after a code change](#redeploying-after-a-code-change)).

---

## Accessing the application

### Quick access (port-forward)

```bash
kubectl port-forward svc/ai-ambitions-frontend 8080:8080 -n ai-ambitions
```

Then open **http://localhost:8080** in your browser. Keep the terminal open — Ctrl+C to stop.

### Public HTTPS access (production)

The ingress (`kubernetes/ingress.yaml`) requires two GCP resources that must be created once:

```bash
# 1. Reserve a global static IP
gcloud compute addresses create ai-ambitions-ip --global --project=mygclearning

# 2. Create a Google-managed SSL certificate (replace with your domain)
gcloud compute ssl-certificates create ai-ambitions-cert \
  --domains=your-domain.example.com --global --project=mygclearning

# 3. Get the reserved IP to set your DNS A record
gcloud compute addresses describe ai-ambitions-ip --global --format="value(address)"
```

Point your DNS `A` record at that IP. GKE will provision the certificate automatically once DNS propagates. The app will be reachable at `https://your-domain.example.com`.

---

## Redeploying after a code change

Push to git — Jenkins (`Jenkinsfile`) builds and pushes both images to Artifact Registry, then updates the image tags in `kubernetes/deployment-backend.yaml` and `kubernetes/deployment-frontend.yaml` and pushes that back to git. ArgoCD picks up the new tags and rolls out both deployments automatically — no manual `kubectl`/`gcloud` commands needed for routine deploys.

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
├── frontend/
│   ├── src/
│   │   ├── App.tsx          Root app, tab routing
│   │   ├── components/      Header, Charts, DataTable, Chat panel
│   │   ├── tabs/            OverviewTab and other tab views
│   │   ├── api/             Typed API clients (overview, query, chat, pdf)
│   │   └── types/           Shared TypeScript types
│   ├── nginx.conf           Serves the built SPA — no /api proxying, Ingress handles routing
│   └── Dockerfile           Frontend-only image (nginx-unprivileged, non-root)
├── kubernetes/
│   ├── configmap.yaml             Non-secret env vars (BQ project, Gemini model, etc.)
│   ├── deployment-backend.yaml    Backend deployment (1 replica, health probes, resource limits)
│   ├── service-backend.yaml       ClusterIP service on 8000
│   ├── deployment-frontend.yaml   Frontend deployment (nginx, non-root uid 101)
│   ├── service-frontend.yaml      ClusterIP service on 8080
│   ├── ingress.yaml               GKE ingress with static IP + managed cert, path-based routing
│   ├── service-account.yaml       Kubernetes SA with Workload Identity annotation
│   └── backend-config.yaml        ForgeRock IG sidecar route config
├── bigquery/
│   └── schema.sql           BigQuery dataset + table DDL
├── Jenkinsfile               CI: build+push both images, update manifests, push to git
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
| `service-backend.yaml` | ClusterIP; routes port 8000 → container 8000 |
| `deployment-frontend.yaml` | 1 replica, 64–128Mi RAM, 50m–200m CPU, readiness + liveness probes on `/`, runs as uid 101 |
| `service-frontend.yaml` | ClusterIP; routes port 8080 → container 8080 |
| `ingress.yaml` | GCE L7 LB; path-based — `/api/*` → backend Service, `/*` → frontend Service; requires `ai-ambitions-ip` static IP and `ai-ambitions-cert` managed cert |
| `service-account.yaml` | KSA `ai-ambitions-ksa` annotated for Workload Identity → `ai-ambitions-app` GCP SA |
| `backend-config.yaml` | ForgeRock IG sidecar route config |

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
Ensure the GCP SA `ai-ambitions-app@mygclearning.iam.gserviceaccount.com` has `roles/bigquery.jobUser` (project-level) and `roles/bigquery.dataEditor` (scoped to the `ai_ambitions` dataset — `dataViewer` is read-only and not sufficient for the admin Excel-upload pipeline), and that the Workload Identity binding is in place (`deploy-gke.sh` handles this automatically).

**Admin upload fails with a GCS or BigQuery error**
Confirm the SA also has `roles/storage.objectAdmin` scoped to the `GCS_UPLOAD_BUCKET`. Separately: don't expose this app publicly until a real ForgeRock IG sidecar is deployed in front of the backend (see the gap note at the top of `kubernetes/deployment-backend.yaml`) — without it, nothing stops a caller from forging the `x-fr-groups` header themselves and granting their own request admin access.

**Frontend pod not starting**
```bash
kubectl describe pod -n ai-ambitions -l app=ai-ambitions-frontend
kubectl logs -n ai-ambitions -l app=ai-ambitions-frontend
```

**Ingress stuck / no ADDRESS**
Run `kubectl describe ingress ai-ambitions -n ai-ambitions` and check Events. Most common causes: static IP `ai-ambitions-ip` not created, or managed cert `ai-ambitions-cert` not created (see [Public HTTPS access](#public-https-access-production) above).
