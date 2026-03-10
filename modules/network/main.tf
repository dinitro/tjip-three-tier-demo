resource "google_compute_network" "main" {
  name                    = "${var.project}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

# Subnet for Cloud Run Direct VPC egress (backend -> Cloud SQL)
resource "google_compute_subnetwork" "cloud_run" {
  name          = "${var.project}-cloudrun"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.main.id
  ip_cidr_range = "10.0.0.0/24"

  private_ip_google_access = true
}

# ==============================================================================
# Private Services Access — allows Cloud SQL to get a private IP
# on the VPC via Google's managed peering
# ==============================================================================

resource "google_compute_global_address" "private_services" {
  name          = "${var.project}-private-svc-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# ==============================================================================
# Firewall — allow Cloud Run egress to reach Cloud SQL (port 5432)
# ==============================================================================

resource "google_compute_firewall" "allow_cloudrun_to_sql" {
  name    = "${var.project}-allow-cr-to-sql"
  project = var.project_id
  network = google_compute_network.main.name

  direction = "EGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  destination_ranges = [google_compute_global_address.private_services.address]

  target_tags = ["cloud-run"]
}
