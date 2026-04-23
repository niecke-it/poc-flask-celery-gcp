variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "api_image" {
  description = "Docker image URI for the Flask API (pushed to Artifact Registry)"
  type        = string
  default     = "api"
}

variable "worker_image" {
  description = "Docker image URI for the Celery worker (pushed to Artifact Registry)"
  type        = string
  default     = "worker"
}

variable "worker_machine_type" {
  description = "Compute Engine machine type for Celery workers"
  type        = string
  default     = "e2-standard-2"
}

variable "worker_min_instances" {
  description = "Minimum Celery worker instances in the MIG"
  type        = number
  default     = 1
}

variable "worker_max_instances" {
  description = "Maximum Celery worker instances in the MIG"
  type        = number
  default     = 3
}
