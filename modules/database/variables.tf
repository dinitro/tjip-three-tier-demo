variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project" {
  description = "Short project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "db_version" {
  description = "The database version to use for the Cloud SQL instance"
  type        = string
}

variable "network_id" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "private_services_access_ready" {
  description = "Dependency signal — private services peering must complete first"
  type        = string
}

variable "db_password" {
  description = "Password for the database user"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_name" {
  description = "Name of the application database"
  type        = string
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
}

variable "availability_type" {
  description = "The availability type for the Cloud SQL instance"
  type        = string
}

variable "disk_size" {
  description = "The size of the data disk in GB"
  type        = number
}

variable "disk_type" {
  description = "The type of data disk"
  type        = string
}

variable "disk_autoresize" {
  description = "Whether or not to automatically increase the storage size when space is running low"
  type        = bool
}

variable "edition" {
  description = "The edition of the Cloud SQL instance"
  type        = string
}
