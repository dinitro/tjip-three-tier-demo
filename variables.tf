variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west4"
}

variable "project" {
  description = "Short project name for resource naming"
  type        = string
  default     = "threetier"
}

variable "db_password" {
  description = "Password for the Cloud SQL postgres user"
  type        = string
  sensitive   = true
}
