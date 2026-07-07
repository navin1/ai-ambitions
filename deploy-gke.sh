#!/usr/bin/env bash
# deploy-gke.sh — one-shot GKE + IAM bootstrap for ai-ambitions (cluster,
# Artifact Registry repo, app service account, Workload Identity binding).
# Safe to run multiple times (all steps are idempotent).
#
# This only provisions infrastructure — it does not build or deploy the app.
# After this completes:
#   1. kubectl apply -f kubernetes/                  (or let ArgoCD do it —
#      see argocd/application.yaml)
#   2. Reserve the Ingress's static IP + managed cert (one-time — see
#      kubernetes/ingress.yaml)
#   3. Push to git / let Jenkins run                  (builds + pushes both
#      the backend and frontend images — see Jenkinsfile)
#
# Usage:
#   chmod +x deploy-gke.sh
#   ./deploy-gke.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_ID="mygclearning"
REGION="us-central1"
CLUSTER="ai-ambitions-cluster"
REPO="ai-ambitions"
NAMESPACE="ai-ambitions"
APP_SA="ai-ambitions-app"
BQ_DATASET="ai_ambitions"          # must match BIGQUERY_DATASET in configmap.yaml
GCS_UPLOAD_BUCKET=""                # must match GCS_UPLOAD_BUCKET in configmap.yaml — required

# ── Helpers ───────────────────────────────────────────────────────────────────
step() { echo; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }

# ── 1. Prerequisite check ─────────────────────────────────────────────────────
step "Checking required tools"
for tool in gcloud kubectl bq; do
  if ! command -v "$tool" &>/dev/null; then
    echo "  ERROR: '$tool' not found. Install it and re-run."
    echo "    gcloud  → https://cloud.google.com/sdk/docs/install"
    echo "    kubectl → gcloud components install kubectl"
    echo "    bq      → included with the Cloud SDK (gcloud components install bq)"
    exit 1
  fi
  ok "$tool found"
done

# ── 2. GCloud auth + project ──────────────────────────────────────────────────
step "Configuring gcloud project and region"
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
ok "project=$PROJECT_ID  region=$REGION"

# ── 3. Enable APIs ────────────────────────────────────────────────────────────
step "Enabling required GCP APIs (may take 1-2 min on first run)"
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com \
  --project="$PROJECT_ID"
ok "APIs enabled"

# ── 4. Artifact Registry repo ─────────────────────────────────────────────────
step "Creating Artifact Registry repo (skips if already exists)"
if gcloud artifacts repositories describe "$REPO" \
     --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
  ok "Repo '$REPO' already exists, skipping"
else
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID"
  ok "Repo '$REPO' created"
fi

# ── 5. GKE cluster ────────────────────────────────────────────────────────────
step "Creating GKE cluster (skips if already exists — takes ~8 min on first run)"
if gcloud container clusters describe "$CLUSTER" \
     --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
  ok "Cluster '$CLUSTER' already exists, skipping"
else
  gcloud container clusters create "$CLUSTER" \
    --region="$REGION" \
    --num-nodes=1 \
    --machine-type=e2-standard-2 \
    --workload-pool="${PROJECT_ID}.svc.id.goog" \
    --project="$PROJECT_ID"
  ok "Cluster '$CLUSTER' created"
fi

# ── 6. kubectl credentials ────────────────────────────────────────────────────
step "Fetching kubectl credentials"
gcloud container clusters get-credentials "$CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID"
ok "kubectl configured for cluster '$CLUSTER'"

# ── 7. App GCP service account (for BigQuery / Workload Identity) ─────────────
step "Creating app GCP service account"
APP_SA_EMAIL="${APP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$APP_SA_EMAIL" \
     --project="$PROJECT_ID" &>/dev/null; then
  ok "Service account '$APP_SA_EMAIL' already exists, skipping"
else
  gcloud iam service-accounts create "$APP_SA" \
    --project="$PROJECT_ID"
  ok "Service account '$APP_SA_EMAIL' created"
fi

step "Granting BigQuery jobUser (project-level — job execution isn't a dataset resource)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${APP_SA_EMAIL}" \
  --role="roles/bigquery.jobUser" \
  --condition=None \
  --quiet
ok "Granted roles/bigquery.jobUser"

step "Granting BigQuery dataEditor, scoped to the '$BQ_DATASET' dataset only"
# dataEditor (not dataViewer) is required: the admin Excel-upload pipeline
# (backend/routes/admin.py -> bigquery_client.replace_periods) creates a
# staging table, runs DELETE+INSERT DML, then drops the staging table.
# Scoped to the dataset (via `bq`, not `gcloud projects`) rather than the
# whole project, so the SA can't write to unrelated datasets.
bq add-iam-policy-binding \
  --member="serviceAccount:${APP_SA_EMAIL}" \
  --role="roles/bigquery.dataEditor" \
  "${PROJECT_ID}:${BQ_DATASET}"
ok "Granted roles/bigquery.dataEditor on dataset '$BQ_DATASET'"

step "Granting Storage objectAdmin, scoped to the upload bucket only"
if [[ -z "$GCS_UPLOAD_BUCKET" ]]; then
  echo "  WARNING: GCS_UPLOAD_BUCKET is not set at the top of this script — skipping."
  echo "  The admin upload pipeline (input/ -> archive/success|failure/) needs"
  echo "  roles/storage.objectAdmin on that bucket. Set GCS_UPLOAD_BUCKET and re-run,"
  echo "  or grant it manually:"
  echo "    gcloud storage buckets add-iam-policy-binding gs://YOUR_BUCKET \\"
  echo "      --member=\"serviceAccount:${APP_SA_EMAIL}\" --role=roles/storage.objectAdmin"
else
  gcloud storage buckets add-iam-policy-binding "gs://${GCS_UPLOAD_BUCKET}" \
    --member="serviceAccount:${APP_SA_EMAIL}" \
    --role="roles/storage.objectAdmin" \
    --quiet
  ok "Granted roles/storage.objectAdmin on gs://$GCS_UPLOAD_BUCKET"
fi

# ── 8. Workload Identity binding ──────────────────────────────────────────────
step "Binding Kubernetes SA to GCP SA (Workload Identity)"
gcloud iam service-accounts add-iam-policy-binding "$APP_SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${NAMESPACE}-ksa]" \
  --project="$PROJECT_ID" \
  --quiet
ok "Workload Identity binding created"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Infra bootstrap complete!"
echo "  Next steps:"
echo "    1. kubectl apply -f kubernetes/                  (or via ArgoCD)"
echo "    2. Reserve the Ingress static IP + managed cert  (one-time, see"
echo "       kubernetes/ingress.yaml)"
echo "    3. Push to git — Jenkins builds + deploys both the backend"
echo "       and frontend images"
echo "  Quick local check once the backend is running:"
echo "    kubectl port-forward svc/ai-ambitions-backend 8000:8000 -n ${NAMESPACE}"
echo "    curl http://localhost:8000/api/health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
