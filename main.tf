provider "google" {
  project = "omega-strand-444013-p0"
  region  = "northamerica-northeast1" # Montreal, Canada
}

# Reference the Existing GKE Cluster (without creating or modifying node pools)
resource "google_container_cluster" "k8s_cluster" {
  name     = "your-existing-cluster-name"  # Replace with your actual cluster name
  location = "northamerica-northeast1"  # Same region as your manually created cluster
  # Autopilot clusters manage nodes automatically, so no node configuration is needed
}

# Google Artifact Registry for Docker Images
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "microservice-docker-repo" # Specify only repository_id
  location      = "northamerica-northeast1"
  format        = "DOCKER"
  description   = "Docker repository for microservice application"
}

# Service Account for ArgoCD
resource "google_service_account" "argocd_sa" {
  account_id   = "argocd"
  display_name = "ArgoCD Service Account"
}

# IAM Binding for ArgoCD Service Account to GKE Cluster
resource "google_project_iam_member" "argocd_bindings" {
  project = "omega-strand-444013-p0" # Required argument
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.argocd_sa.email}"
}

# Build and Push Docker Images to Artifact Registry
resource "null_resource" "build_and_push_images" {
  provisioner "local-exec" {
    command = <<EOT
    REM Build and Push Docker Images
    docker build -t northamerica-northeast1-docker.pkg.dev/${google_artifact_registry_repository.docker_repo.name}/frontend-service:latest ./frontend
    docker push northamerica-northeast1-docker.pkg.dev/${google_artifact_registry_repository.docker_repo.name}/frontend-service:latest
    docker build -t northamerica-northeast1-docker.pkg.dev/${google_artifact_registry_repository.docker_repo.name}/backend-service:latest ./backend
    docker push northamerica-northeast1-docker.pkg.dev/${google_artifact_registry_repository.docker_repo.name}/backend-service:latest
    EOT
  }
}

# Install ArgoCD on Kubernetes
resource "null_resource" "install_argocd" {
  provisioner "local-exec" {
    command = <<EOT
    REM Configure Kubernetes Context and Install ArgoCD
    gcloud container clusters get-credentials your-existing-cluster-name --zone northamerica-northeast1
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    REM Patch the ArgoCD server service to use LoadBalancer type
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    EOT
  }
}

# Output Artifact Registry Repository
output "artifact_repo" {
  value = google_artifact_registry_repository.docker_repo.name
}

# Output ArgoCD Service Account Email
output "argocd_service_account_email" {
  value = google_service_account.argocd_sa.email
}
