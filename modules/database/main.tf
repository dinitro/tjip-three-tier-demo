# Random suffix avoids Cloud SQL's 7-day name reuse restriction on destroy/recreate
resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "main" {
  name             = "${var.project_id}-db-${random_id.db_suffix.hex}"
  project          = var.project_id
  region           = var.region
  database_version = var.db_version

  deletion_protection = false

  settings {
    tier              = var.db_tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize
    edition           = var.edition

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    backup_configuration {
      enabled = false
    }
  }

  depends_on = [var.private_services_access_ready]
}

resource "google_sql_database" "app" {
  name     = var.db_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = var.db_user
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = var.db_password
}
