# ==============================================================================
# Creates the GCS bucket for Terraform remote state
#
# Run this ONCE before main project:
#   cd bootstrap
#   terraform init
#   terraform apply
#
# Intentionally separate so the state bucket itself isn't managed
# by the state it stores.
# ==============================================================================

terraform {
  required_version = ">= 1.14.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "tjip-three-tier-demo"
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "europe-west4"
}

variable "project" {
  description = "Short project name used for resource naming"
  type        = string
  default     = "threetier"
}

# Ensure the storage API is enabled
resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Random suffix ensures uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "tfstate" {
  name     = "${var.project}-tfstate-${random_id.bucket_suffix.hex}"
  project  = var.project_id
  location = var.region

  # Prevent accidental deletion of the state bucket
  force_destroy = false

  # Object versioning - allows state recovery if corrupted or overwritten
  versioning {
    enabled = true
  }

  # Automatically clean up old state versions after 30 days
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  # Uniform bucket-level access (best practice — disables per-object ACLs)
  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage]
}

output "bucket_name" {
  value = google_storage_bucket.tfstate.name
}

output "backend_config" {
  description = "Copy this block into providers.tf backend"
  value       = <<-EOT

    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.tfstate.name}"
        prefix = "terraform/state"
      }
    }

  EOT
}
