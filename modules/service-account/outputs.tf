output "email" {
  description = "Email address of the service account"
  value       = google_service_account.sa.email
}

output "id" {
  description = "Fully-qualified ID of the service account"
  value       = google_service_account.sa.id
}

output "name" {
  description = "Fully-qualified name of the service account"
  value       = google_service_account.sa.name
}
