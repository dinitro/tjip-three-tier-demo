output "frontend_url" {
  description = "Public URL of the frontend Cloud Run service"
  value       = module.frontend.url
}

output "backend_url" {
  description = "Internal URL of the backend Cloud Run service (not publicly accessible)"
  value       = module.backend.url
}

output "database_private_ip" {
  description = "Private IP of the Cloud SQL instance (VPC only)"
  value       = module.database.private_ip
}

output "database_connection_name" {
  description = "Cloud SQL connection name (project:region:instance)"
  value       = module.database.connection_name
}
