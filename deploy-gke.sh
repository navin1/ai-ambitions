#!/usr/bin/env bash
# deploy-gke.sh — one-shot GKE setup + Cloud Build deploy for ai-ambitions
# Safe to run multiple times (all steps are idempotent).
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

# ── Helpers ───────────────────────────────────────────────────────────────────
step() { echo; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }

# ── 1. Prerequisite check ─────────────────────────────────────────────────────
step "Checking required tools"
for tool in gcloud kubectl; do
  if ! command -v "$tool" &>/dev/null; then
    echo "  ERROR: '$tool' not found. Install it and re-run."
    echo "    gcloud  → https://cloud.google.com/sdk/docs/install"
    echo "    kubectl → gcloud components install kubectl"
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
  cloudbuild.googleapis.com \
  iam.googleapis.com \
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

# ── 5. Cloud Build service account permissions ────────────────────────────────
step "Granting Cloud Build SA permissions"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/container.developer" \
  --condition=None \
  --quiet
ok "Granted roles/container.developer to Cloud Build SA"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/artifactregistry.writer" \
  --condition=None \
  --quiet
ok "Granted roles/artifactregistry.writer to Cloud Build SA"

# cloud-sdk builder steps inside Cloud Build authenticate via the Compute Engine
# default SA (metadata server), not the Cloud Build SA. container.clusters.get
# (required by get-credentials) is not in container.developer, so grant viewer.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/container.viewer" \
  --condition=None \
  --quiet
ok "Granted roles/container.viewer to Compute Engine default SA (used by cloud-sdk builder)"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/container.developer" \
  --condition=None \
  --quiet
ok "Granted roles/container.developer to Compute Engine default SA"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/artifactregistry.writer" \
  --condition=None \
  --quiet
ok "Granted roles/artifactregistry.writer to Compute Engine default SA"

# ── 6. GKE cluster ────────────────────────────────────────────────────────────
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

# ── 7. kubectl credentials ────────────────────────────────────────────────────
step "Fetching kubectl credentials"
gcloud container clusters get-credentials "$CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID"
ok "kubectl configured for cluster '$CLUSTER'"

# ── 8. App GCP service account (for BigQuery / Workload Identity) ─────────────
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

step "Granting BigQuery roles to app service account"
for role in roles/bigquery.dataViewer roles/bigquery.jobUser; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${APP_SA_EMAIL}" \
    --role="$role" \
    --condition=None \
    --quiet
  ok "Granted $role"
done

# ── 9. Workload Identity binding ──────────────────────────────────────────────
step "Binding Kubernetes SA to GCP SA (Workload Identity)"
gcloud iam service-accounts add-iam-policy-binding "$APP_SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${NAMESPACE}-ksa]" \
  --project="$PROJECT_ID" \
  --quiet
ok "Workload Identity binding created"

# ── 10. Cloud Build submit ────────────────────────────────────────────────────
step "Submitting Cloud Build (build → push → deploy to GKE)"
echo "  This streams live logs and takes ~5-8 minutes."
echo
gcloud builds submit \
  --config=cloudbuild.yaml \
  --project="$PROJECT_ID"

# ── 11. Verify ────────────────────────────────────────────────────────────────
step "Verifying deployment"
kubectl get pods -n "$NAMESPACE"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploy complete!"
echo "  Access the app:"
echo "    kubectl port-forward svc/${NAMESPACE} 8080:80 -n ${NAMESPACE}"
echo "  Then open: http://localhost:8080"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
