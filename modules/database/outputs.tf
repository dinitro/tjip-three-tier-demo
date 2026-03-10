output "private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "connection_string" {
  description = "PostgreSQL connection string for applications"
  sensitive   = true
  value       = "postgresql://${google_sql_user.app.name}:${var.db_password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.app.name}?sslmode=require"
}

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}
