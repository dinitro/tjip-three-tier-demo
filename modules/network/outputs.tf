output "network_id" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "cloud_run_subnet_name" {
  description = "Name of the Cloud Run subnet"
  value       = google_compute_subnetwork.cloud_run.name
}

output "private_services_access_ready" {
  description = "Signals that private services peering is complete"
  value       = google_service_networking_connection.private_services.id
}
