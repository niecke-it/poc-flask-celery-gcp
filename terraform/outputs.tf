output "api_url" {
  description = "Cloud Run API endpoint"
  value       = google_cloud_run_v2_service.api.uri
}

output "artifact_registry_url" {
  description = "Base URL for Docker images in Artifact Registry"
  value       = google_artifact_registry_repository.repo.registry_uri
}

output "redis_host" {
  description = "Memorystore Redis private IP (only reachable within VPC)"
  value       = google_redis_instance.cache.host
  sensitive   = true
}

output "worker_mig" {
  description = "Celery worker Managed Instance Group name"
  value       = google_compute_instance_group_manager.workers.name
}
