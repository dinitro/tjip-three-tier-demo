variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "image" {
  description = "Container image to deploy"
  type        = string
}

variable "port" {
  description = "Container port to expose"
  type        = number
}

variable "service_account" {
  description = "Email of the service account to run the container as"
  type        = string
}

variable "ingress" {
  description = "Ingress setting"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "allow_public" {
  description = "Whether to allow unauthenticated (public) access"
  type        = bool
}

variable "min_instance_count" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
}

variable "cpu" {
  description = "CPU limit for the container"
  type        = string
}

variable "cpu_idle" {
  type = bool
}

variable "memory" {
  description = "Memory limit for the container"
  type        = string
}

variable "env_vars" {
  description = "Map of environment variable name -> value"
  type        = map(string)
  default     = {}
}

variable "vpc_access" {
  description = "Optional Direct VPC egress configuration"
  type = object({
    network    = string
    subnetwork = string
    tags       = list(string)
    egress     = string
  })
  default = null
}
