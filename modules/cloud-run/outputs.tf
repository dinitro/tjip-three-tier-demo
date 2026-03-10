output "url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.cloud_run.uri
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.cloud_run.name
}

output "service_id" {
  description = "Fully qualified ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.cloud_run.id
}

output "latest_revision" {
  description = "Name of the latest ready revision"
  value       = google_cloud_run_v2_service.cloud_run.latest_ready_revision
}
