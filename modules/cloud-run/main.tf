resource "google_cloud_run_v2_service" "cloud_run" {
  name                = var.name
  location            = var.region
  project             = var.project_id
  ingress             = var.ingress
  deletion_protection = false

  template {
    service_account = var.service_account

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    # --- Direct VPC egress ---
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        network_interfaces {
          network    = vpc_access.value.network
          subnetwork = vpc_access.value.subnetwork
          tags       = vpc_access.value.tags
        }
        egress = vpc_access.value.egress
      }
    }

    containers {
      name  = var.name
      image = var.image

      ports {
        container_port = var.port
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = var.cpu_idle
      }

      startup_probe {
        tcp_socket {
          port = var.port
        }
        initial_delay_seconds = 0
        period_seconds        = 3
        failure_threshold     = 3
      }
    }
  }
}

# --- Public access IAM (only when allow_public = true) ---
resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_public ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.cloud_run.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
