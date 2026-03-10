# ==============================================================================
# Service Account Module — reusable SA with configurable project-level roles
# ==============================================================================

resource "google_service_account" "sa" {
  account_id   = var.name
  display_name = var.display
  project      = var.project_id
}

resource "google_project_iam_member" "roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}
