#!/bin/sh
# One-time provisioning for a manually managed Google Cloud HTTP(S) Load
# Balancer that serves the frontend straight out of a GCS bucket and routes
# /api/* to the backend running in GKE.
#
# Why manual instead of a Kubernetes Ingress resource: a GKE-managed Ingress
# (kubernetes.io/ingress.class: "gce") can only point at Kubernetes Services,
# not at a GCS bucket — a Backend Bucket isn't expressible in that object.
# Mixing a backend bucket (frontend) and a backend service (API) behind one
# load balancer requires creating the URL map yourself via gcloud, as below.
#
# Run this once per environment. It is NOT idempotent — re-running create
# commands on existing resources will error (harmlessly) rather than update
# them. Review every value before running; nothing here runs automatically.
#
# Prerequisites:
#   - kubernetes/service-backend.yaml applied (its NEG annotation is what
#     lets step 6 find the backend NEG)
#   - kubernetes/deployment-backend.yaml applied and pods Running/Ready
set -eu

PROJECT_ID="mygclearning"
REGION="us-central1"
ZONE="us-central1-a"          # adjust to match your node pool's zone(s)
NAMESPACE="ai-ambitions"
BUCKET_NAME="ai-ambitions-frontend-${PROJECT_ID}"
DOMAIN="your-domain.example.com"   # update before running

# 1. Create the GCS bucket that will hold the built frontend (frontend/dist).
#    Synced by the Jenkins pipeline on every deploy — see Jenkinsfile.
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

# 2. Make bucket objects publicly readable — required for a Backend Bucket
#    to serve them over the load balancer.
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member="allUsers" \
  --role="roles/storage.objectViewer"

# 3. Set index.html as the bucket's "not found" page too, so SPA client-side
#    routes (e.g. /reports/123) fall back to index.html instead of a GCS 404.
gcloud storage buckets update "gs://${BUCKET_NAME}" \
  --web-main-page-suffix=index.html \
  --web-error-page=index.html

# 4. Create the Backend Bucket resource, with Cloud CDN enabled.
gcloud compute backend-buckets create ai-ambitions-frontend-bucket \
  --gcs-bucket-name="${BUCKET_NAME}" \
  --enable-cdn \
  --project="${PROJECT_ID}"

# 5. Reserve a global static IP and a managed SSL cert for the domain.
gcloud compute addresses create ai-ambitions-ip --global --project="${PROJECT_ID}"
gcloud compute ssl-certificates create ai-ambitions-cert \
  --domains="${DOMAIN}" --global --project="${PROJECT_ID}"
# Point your DNS A record at the reserved IP now:
gcloud compute addresses describe ai-ambitions-ip --global --format="value(address)"

# 6. Find the standalone NEG that GKE created for the backend Service (from
#    the cloud.google.com/neg annotation in service-backend.yaml). The name
#    is auto-generated; this lists candidates so you can pick the right one.
gcloud compute network-endpoint-groups list \
  --filter="name~ai-ambitions-backend" \
  --project="${PROJECT_ID}"
# Copy the NEG name into NEG_NAME below, then continue.
NEG_NAME="REPLACE_WITH_NEG_NAME_FROM_ABOVE"

# 7. Create the backend service for the API and attach the NEG.
gcloud compute backend-services create ai-ambitions-backend-svc \
  --global \
  --protocol=HTTP \
  --port-name=http \
  --project="${PROJECT_ID}"

gcloud compute backend-services add-backend ai-ambitions-backend-svc \
  --global \
  --network-endpoint-group="${NEG_NAME}" \
  --network-endpoint-group-zone="${ZONE}" \
  --project="${PROJECT_ID}"

# 8. Health check for the backend service (mirrors the readiness probe).
gcloud compute health-checks create http ai-ambitions-backend-hc \
  --port=8000 \
  --request-path=/api/health \
  --project="${PROJECT_ID}"

gcloud compute backend-services update ai-ambitions-backend-svc \
  --global \
  --health-checks=ai-ambitions-backend-hc \
  --project="${PROJECT_ID}"

# 9. URL map: /api/* -> backend service (GKE), everything else -> bucket.
gcloud compute url-maps create ai-ambitions-url-map \
  --default-backend-bucket=ai-ambitions-frontend-bucket \
  --project="${PROJECT_ID}"

gcloud compute url-maps add-path-matcher ai-ambitions-url-map \
  --path-matcher-name=api-matcher \
  --default-backend-bucket=ai-ambitions-frontend-bucket \
  --path-rules="/api/*=ai-ambitions-backend-svc" \
  --new-hosts="${DOMAIN}" \
  --project="${PROJECT_ID}"

# 10. Target HTTPS proxy + global forwarding rule, using the reserved IP.
gcloud compute target-https-proxies create ai-ambitions-https-proxy \
  --url-map=ai-ambitions-url-map \
  --ssl-certificates=ai-ambitions-cert \
  --project="${PROJECT_ID}"

gcloud compute forwarding-rules create ai-ambitions-https-rule \
  --global \
  --target-https-proxy=ai-ambitions-https-proxy \
  --address=ai-ambitions-ip \
  --ports=443 \
  --project="${PROJECT_ID}"

echo "Done. DNS A record for ${DOMAIN} should point at the address printed in step 5."
echo "Managed cert provisioning can take up to ~60 minutes after DNS propagates."
