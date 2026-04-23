resource "google_service_account" "api" {
  account_id   = "poc-api-sa"
  display_name = "POC Flask API (Cloud Run)"
  project      = var.project_id
}

resource "google_service_account" "worker" {
  account_id   = "poc-worker-sa"
  display_name = "POC Celery Worker (Compute Engine MIG)"
  project      = var.project_id
}

# Worker needs to pull its own container image from Artifact Registry
resource "google_project_iam_member" "worker_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

# Cloud Build (2nd gen) runs as the Compute Engine default SA, not @cloudbuild.gserviceaccount.com
data "google_project" "project" {}

locals {
  compute_sa = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_project_iam_member" "cloudbuild_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_project_iam_member" "cloudbuild_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_project_iam_member" "api_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api.email}"
}
