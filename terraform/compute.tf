data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

resource "google_compute_instance_template" "worker" {
  name_prefix  = "poc-worker-"
  machine_type = var.worker_machine_type
  region       = var.region

  tags = ["celery-worker"]

  disk {
    source_image = data.google_compute_image.cos.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    # No access_config = no public IP; Artifact Registry reached via private_ip_google_access
  }

  metadata = {
    "google-logging-enabled"    = "true"
    "google-monitoring-enabled" = "true"
    "startup-script"            = <<-EOT
      #!/bin/bash
      set -euo pipefail

      WORKER_IMAGE="${google_artifact_registry_repository.repo.registry_uri}/${var.worker_image}"
      REDIS_HOST="${google_redis_instance.cache.host}"
      REDIS_PORT="6379"

      # set DOCKER_CONFIG to something writable
      export DOCKER_CONFIG=/tmp/docker-config
      docker-credential-gcr configure-docker --registries=${var.region}-docker.pkg.dev

      docker pull "$WORKER_IMAGE"

      docker run -d \
        --restart=unless-stopped \
        --name=celery-worker \
        --log-driver=gcplogs \
        -e REDIS_HOST="$REDIS_HOST" \
        -e REDIS_PORT="$REDIS_PORT" \
        "$WORKER_IMAGE"
    EOT
  }

  service_account {
    email  = google_service_account.worker.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_artifact_registry_repository.repo,
    google_project_iam_member.worker_ar_reader,
  ]
}

resource "google_compute_instance_group_manager" "workers" {
  name               = "poc-worker-mig"
  base_instance_name = "poc-worker"
  zone               = "${var.region}-b"

  version {
    instance_template = google_compute_instance_template.worker.id
  }

  target_size = var.worker_min_instances
}

resource "google_compute_autoscaler" "workers" {
  name   = "poc-worker-autoscaler"
  zone   = "${var.region}-b"
  target = google_compute_instance_group_manager.workers.id

  autoscaling_policy {
    max_replicas    = var.worker_max_instances
    min_replicas    = var.worker_min_instances
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}
