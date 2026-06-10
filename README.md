# AI Ambitions Dashboard

An executive dashboard for tracking AI investment, ROI, and use case metrics — built with React + FastAPI, deployed on Google Kubernetes Engine.

---

## Architecture

```
Browser → GKE Ingress → ai-ambitions pod (FastAPI + React SPA)
                                 │
                        BigQuery (data)
                        Vertex AI / Gemini (AI features, optional)
```

- **Frontend:** React + TypeScript + Vite, served as static files by FastAPI
- **Backend:** FastAPI (Python 3.12), Playwright for PDF export
- **Auth:** ForgeRock Identity Gateway sidecar (prod) / dev-fallback (local)
- **Data:** BigQuery (`ai_ambitions` dataset)
- **Container registry:** Artifact Registry (`us-central1`)
- **Cluster:** GKE regional cluster (`us-central1`), Workload Identity

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

## One-shot deploy to GKE

`deploy-gke.sh` is idempotent — safe to run on a fresh project or re-run for updates.

```bash
chmod +x deploy-gke.sh
./deploy-gke.sh
```

What it does (in order):

1. Checks `gcloud` and `kubectl` are installed
2. Sets project `mygclearning` and region `us-central1`
3. Enables required GCP APIs (Container, Artifact Registry, Cloud Build, IAM)
4. Creates Artifact Registry repo `ai-ambitions` (skips if exists)
5. Grants Cloud Build SA and Compute Engine SA the roles needed to push images and deploy to GKE
6. Creates GKE cluster `ai-ambitions-cluster` (skips if exists — takes ~8 min first run)
7. Fetches `kubectl` credentials for the cluster
8. Creates GCP service account `ai-ambitions-app` with BigQuery roles
9. Binds it to the Kubernetes SA via Workload Identity
10. Submits a Cloud Build job (`cloudbuild.yaml`) — builds image, pushes, applies manifests, rolls out
11. Verifies pods are running

Expected output on success:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Deploy complete!
  Access the app:
    kubectl port-forward svc/ai-ambitions 8080:80 -n ai-ambitions
  Then open: http://localhost:8080
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Accessing the application

### Quick access (port-forward)

```bash
kubectl port-forward svc/ai-ambitions 8080:80 -n ai-ambitions
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

Just resubmit Cloud Build — no need to re-run the full `deploy-gke.sh`:

```bash
gcloud builds submit --config=cloudbuild.yaml --project=mygclearning
```

To enable the AI chat / NL features (off by default):

```bash
gcloud builds submit --config=cloudbuild.yaml --project=mygclearning \
  --substitutions=_VITE_ENABLE_AI_FEATURES=true
```

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
│   ├── main.py              App entry point, SPA static serving
│   ├── auth.py              ForgeRock IG header auth + BigQuery credentials
│   ├── bigquery_client.py   BigQuery query helpers
│   ├── gemini_client.py     Vertex AI / Gemini client
│   ├── schemas.py           Pydantic request/response models
│   ├── assets/              logo.png, star.png (used in PDF export + favicon)
│   └── routes/
│       ├── overview.py      KPI and investment drill-down endpoints
│       ├── query.py         Ad-hoc BigQuery query endpoint
│       ├── chat.py          AI chat endpoint (requires Vertex AI)
│       └── pdf.py           PDF export via Playwright + Chart.js
├── frontend/
│   ├── src/
│   │   ├── App.tsx          Root app, tab routing
│   │   ├── components/      Header, Charts, DataTable, Chat panel
│   │   ├── tabs/            OverviewTab and other tab views
│   │   ├── api/             Typed API clients (overview, query, chat, pdf)
│   │   └── types/           Shared TypeScript types
│   └── public/
│       └── logo.png         App logo (served at /logo.png)
├── kubernetes/
│   ├── configmap.yaml       Non-secret env vars (BQ project, Gemini model, etc.)
│   ├── deployment.yaml      App deployment (1 replica, health probes, resource limits)
│   ├── service.yaml         ClusterIP service on port 80 → 8000
│   ├── ingress.yaml         GCE ingress with static IP + managed cert
│   ├── service-account.yaml Kubernetes SA with Workload Identity annotation
│   └── backend-config.yaml  GKE BackendConfig (health check, timeout, IAP)
├── bigquery/
│   └── schema.sql           BigQuery dataset + table DDL
├── Dockerfile               Multi-stage: Node (frontend build) + Python 3.12 (runtime)
├── cloudbuild.yaml          Cloud Build pipeline: build → push → deploy
├── deploy-gke.sh            One-shot GKE setup + deploy script
└── .env.example             Environment variable reference (copy to .env for local dev)
```

---

## Kubernetes manifests reference

| File | Purpose |
|------|---------|
| `configmap.yaml` | Environment config — update `BIGQUERY_PROJECT_ID`, `BIGQUERY_DATASET`, `GEMINI_MODEL` as needed |
| `deployment.yaml` | 1 replica, 512Mi–1Gi RAM, 250m–1 CPU, readiness + liveness probes on `/api/health` |
| `service.yaml` | ClusterIP; routes port 80 → container 8000 |
| `ingress.yaml` | GCE L7 LB; requires `ai-ambitions-ip` static IP and `ai-ambitions-cert` managed cert |
| `service-account.yaml` | KSA `ai-ambitions-ksa` annotated for Workload Identity → `ai-ambitions-app` GCP SA |
| `backend-config.yaml` | 60s timeout, `/api/health` health check, optional IAP config |

---

## Troubleshooting

**Pod not starting**
```bash
kubectl describe pod -n ai-ambitions
kubectl logs -n ai-ambitions -l app=ai-ambitions
```

**PDF export fails**
The container runs Playwright Chromium. Check logs for `BrowserType.launch` errors. The `Dockerfile` sets `PLAYWRIGHT_BROWSERS_PATH=/ms-playwright` so Chromium is accessible to the non-root `appuser`.

**BigQuery auth errors**
Ensure the GCP SA `ai-ambitions-app@mygclearning.iam.gserviceaccount.com` has `roles/bigquery.dataViewer` and `roles/bigquery.jobUser`, and that the Workload Identity binding is in place (`deploy-gke.sh` handles this automatically).

**Ingress stuck / no ADDRESS**
Run `kubectl describe ingress ai-ambitions -n ai-ambitions` and check Events. Most common causes: static IP `ai-ambitions-ip` not created, or managed cert `ai-ambitions-cert` not created (see [Public HTTPS access](#public-https-access-production) above).

**Cloud Build step 2 fails (get-credentials 403)**
`deploy-gke.sh` grants `roles/container.viewer` and `roles/container.developer` to both the Cloud Build SA and the Compute Engine default SA. Re-run the script if permissions were changed.
