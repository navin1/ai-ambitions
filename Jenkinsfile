// CI pipeline: build the backend image and push it to Artifact Registry,
// build the frontend SPA and sync it straight to its GCS bucket (served by
// a manually managed Compute load balancer — see
// kubernetes/setup-static-frontend-lb.sh — not by a container), then update
// the backend image tag in kubernetes/deployment-backend.yaml and push back
// to git. ArgoCD (in the GKE cluster) watches this repo's kubernetes/ path
// and syncs the new tag automatically — this pipeline does not call kubectl
// directly.
//
// Prerequisites:
//   - Jenkins agent runs as a pod in a GKE cluster with Workload Identity
//     enabled, bound to a GCP service account with:
//       roles/artifactregistry.writer   (push backend image)
//       roles/storage.objectAdmin       (sync frontend bucket)
//     Bind it the same way as kubernetes/service-account.yaml does for the
//     app SA, but using a separate SA/KSA for Jenkins, e.g. jenkins-build-ksa.
//   - The agent image has docker, gcloud, and git available.
//   - A Jenkins credential (Username/Password or SSH key) with push access
//     to this repo, referenced below as GIT_PUSH_CREDENTIALS_ID.

pipeline {
    agent any

    environment {
        PROJECT_ID    = 'mygclearning'
        REGION        = 'us-central1'
        REPO          = 'ai-ambitions'
        BACKEND_IMAGE = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/ai-ambitions-backend"
        IMAGE_TAG     = "${env.GIT_COMMIT.take(7)}"
        FRONTEND_BUCKET = "ai-ambitions-frontend-${PROJECT_ID}"
        VITE_ENABLE_AI_FEATURES = 'false'   // set to 'true' to bundle AI/chat features
        GIT_PUSH_CREDENTIALS_ID = 'git-push-credentials'   // update to your Jenkins credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Configure Docker auth') {
            steps {
                // Workload Identity provides ambient credentials to this pod's
                // GCP service account — no key file, just wire up the
                // Artifact Registry credential helper.
                sh "gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet"
            }
        }

        stage('Build & push backend image') {
            steps {
                sh """
                    docker build \
                        -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                        -t ${BACKEND_IMAGE}:latest \
                        backend/
                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest
                """
            }
        }

        stage('Build & sync frontend') {
            steps {
                // Build inside a node:20-alpine container so the Jenkins
                // agent itself doesn't need Node installed.
                sh """
                    docker run --rm \
                        -v "\$(pwd)/frontend:/app" -w /app \
                        -e VITE_ENABLE_AI_FEATURES=${VITE_ENABLE_AI_FEATURES} \
                        node:20-alpine sh -c "npm ci && npm run build"

                    gcloud storage rsync frontend/dist "gs://${FRONTEND_BUCKET}" \
                        --recursive --delete-unmatched-destination-objects

                    gcloud compute url-maps invalidate-cdn-cache ai-ambitions-url-map \
                        --path "/*" --async
                """
            }
        }

        stage('Update backend manifest & push to git') {
            steps {
                sh """
                    sed -i.bak -E 's#image: .*/ai-ambitions-backend:.*#image: ${BACKEND_IMAGE}:${IMAGE_TAG}#' kubernetes/deployment-backend.yaml
                    rm kubernetes/deployment-backend.yaml.bak
                """
                withCredentials([usernamePassword(
                    credentialsId: "${GIT_PUSH_CREDENTIALS_ID}",
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins-ci@${PROJECT_ID}.iam.gserviceaccount.com"
                        git config user.name "jenkins-ci"
                        git add kubernetes/deployment-backend.yaml
                        git commit -m "ci: deploy ai-ambitions-backend ${IMAGE_TAG}" || echo "No changes to commit"
                        git push https://${GIT_USER}:${GIT_TOKEN}@\$(git remote get-url origin | sed -E 's#https?://##') HEAD:${env.GIT_BRANCH ?: 'main'}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pushed ${BACKEND_IMAGE}:${IMAGE_TAG} (ArgoCD will sync) and synced frontend/dist to gs://${FRONTEND_BUCKET}"
        }
    }
}
