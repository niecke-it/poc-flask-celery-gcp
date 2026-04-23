terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",     # Artifact Registry (Docker images)
    "cloudbuild.googleapis.com",           # Cloud Build (remote image builds)
    "cloudresourcemanager.googleapis.com", # Terraform IAM operations
    "compute.googleapis.com",              # VPC, firewall, MIG, autoscaler
    "iam.googleapis.com",                  # Service accounts + IAM bindings
    "logging.googleapis.com",              # Cloud Logging (gcplogs driver + Cloud Run)
    "monitoring.googleapis.com",           # Cloud Monitoring (worker metrics)
    "redis.googleapis.com",                # Memorystore Redis
    "run.googleapis.com",                  # Cloud Run
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
