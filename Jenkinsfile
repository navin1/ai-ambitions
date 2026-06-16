// CI pipeline: build the frontend and backend images, push both to Artifact
// Registry, then update the image tags in kubernetes/deployment-*.yaml and
// push back to git. ArgoCD (in the GKE cluster) watches this repo's
// kubernetes/ path and syncs the new tags automatically — this pipeline does
// not call kubectl directly.
//
// Prerequisites:
//   - Jenkins agent runs as a pod in a GKE cluster with Workload Identity
//     enabled, bound to a GCP service account with:
//       roles/artifactregistry.writer  (push images)
//     Bind it the same way as kubernetes/service-account.yaml does for the
//     app SA, but using a separate SA/KSA for Jenkins, e.g. jenkins-build-ksa.
//   - The agent image has docker, gcloud, and git available.
//   - A Jenkins credential (Username/Password or SSH key) with push access
//     to this repo, referenced below as GIT_PUSH_CREDENTIALS_ID.

pipeline {
    agent any

    environment {
        PROJECT_ID     = 'mygclearning'
        REGION         = 'us-central1'
        REPO           = 'ai-ambitions'
        BACKEND_IMAGE  = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/ai-ambitions-backend"
        FRONTEND_IMAGE = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/ai-ambitions-frontend"
        IMAGE_TAG      = "${env.GIT_COMMIT.take(7)}"
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

        stage('Build images') {
            steps {
                sh """
                    docker build \
                        -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                        -t ${BACKEND_IMAGE}:latest \
                        backend/

                    docker build \
                        --build-arg VITE_ENABLE_AI_FEATURES=${VITE_ENABLE_AI_FEATURES} \
                        -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                        -t ${FRONTEND_IMAGE}:latest \
                        frontend/
                """
            }
        }

        stage('Push images') {
            steps {
                sh """
                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest
                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Update manifests & push to git') {
            steps {
                sh """
                    sed -i.bak -E 's#image: .*/ai-ambitions-backend:.*#image: ${BACKEND_IMAGE}:${IMAGE_TAG}#' kubernetes/deployment-backend.yaml
                    sed -i.bak -E 's#image: .*/ai-ambitions-frontend:.*#image: ${FRONTEND_IMAGE}:${IMAGE_TAG}#' kubernetes/deployment-frontend.yaml
                    rm kubernetes/deployment-backend.yaml.bak kubernetes/deployment-frontend.yaml.bak
                """
                withCredentials([usernamePassword(
                    credentialsId: "${GIT_PUSH_CREDENTIALS_ID}",
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins-ci@${PROJECT_ID}.iam.gserviceaccount.com"
                        git config user.name "jenkins-ci"
                        git add kubernetes/deployment-backend.yaml kubernetes/deployment-frontend.yaml
                        git commit -m "ci: deploy ai-ambitions ${IMAGE_TAG}" || echo "No changes to commit"
                        git push https://${GIT_USER}:${GIT_TOKEN}@\$(git remote get-url origin | sed -E 's#https?://##') HEAD:${env.GIT_BRANCH ?: 'main'}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pushed ${BACKEND_IMAGE}:${IMAGE_TAG} and ${FRONTEND_IMAGE}:${IMAGE_TAG} — ArgoCD will sync the new tags from kubernetes/"
        }
    }
}
