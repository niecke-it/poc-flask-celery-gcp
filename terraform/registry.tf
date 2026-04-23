resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "poc-registry"
  description   = "Docker images for POC Flask API and Celery worker"
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
