resource "google_compute_network" "vpc" {
  name                    = "poc-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "poc-subnet"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}


resource "google_compute_firewall" "allow_internal" {
  name    = "poc-allow-internal"
  network = google_compute_network.vpc.name

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = ["10.0.0.0/24"]
}

# GCP health-check probe ranges — required for MIG auto-healing
resource "google_compute_firewall" "allow_health_check" {
  name    = "poc-allow-health-check"
  network = google_compute_network.vpc.name

  allow { protocol = "tcp" }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["celery-worker"]
}
