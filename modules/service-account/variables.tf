variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Service account ID"
  type        = string
}

variable "display" {
  description = "Human-readable display name"
  type        = string
}

variable "project_roles" {
  description = "List of IAM roles to grant at the project level"
  type        = list(string)
  default     = []
}
