########### Root Module ###########

# --- Networking ---

module "network" {
  source = "./modules/network"

  project_id = var.project_id
  project    = var.project
  region     = var.region

  depends_on = [google_project_service.apis]
}

# --- Service Accounts ---

module "sa_frontend" {
  source = "./modules/service-account"

  project_id = var.project_id
  name       = "sa-${var.project}-frontend"
  display    = "Frontend Cloud Run SA"

  project_roles = []

  depends_on = [google_project_service.apis]
}

module "sa_backend" {
  source = "./modules/service-account"

  project_id = var.project_id
  name       = "sa-${var.project}-backend"
  display    = "Backend Cloud Run SA"

  project_roles = [
    "roles/cloudsql.client", # Allows connection to Cloud SQL
  ]

  depends_on = [google_project_service.apis]
}

# --- Tier 3: Data ---

module "database" {
  source = "./modules/database"

  project_id = var.project_id
  project    = var.project
  region     = var.region
  db_version = "POSTGRES_16"

  db_name     = "appdb"
  db_user     = "appuser"
  db_password = var.db_password

  db_tier           = "db-f1-micro"
  availability_type = "ZONAL"
  disk_size         = 10
  disk_type         = "PD_HDD"
  disk_autoresize   = false
  edition           = "ENTERPRISE"

  network_id                    = module.network.network_id
  private_services_access_ready = module.network.private_services_access_ready

  depends_on = [google_project_service.apis]
}

# --- Tier 2: Application (Backend) ---

module "backend" {
  source = "./modules/cloud-run"

  project_id = var.project_id
  region     = var.region

  cpu                = "0.5"
  memory             = "512Mi"
  cpu_idle           = true
  min_instance_count = 0
  max_instance_count = 1

  name            = "${var.project}-backend"
  image           = "mendhak/http-https-echo:latest"
  port            = 8080
  service_account = module.sa_backend.email
  ingress         = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_public    = false

  env_vars = {
    HTTP_PORT    = "8080"
    DATABASE_URL = module.database.connection_string
  }

  vpc_access = {
    network    = module.network.network_name
    subnetwork = module.network.cloud_run_subnet_name
    tags       = ["cloud-run"]
    egress     = "PRIVATE_RANGES_ONLY"
  }

  depends_on = [google_project_service.apis]
}

# --- Tier 1: Presentation (Frontend) ---

module "frontend" {
  source = "./modules/cloud-run"

  project_id = var.project_id
  region     = var.region

  cpu                = "0.5"
  memory             = "512Mi"
  cpu_idle           = true
  min_instance_count = 0
  max_instance_count = 1

  name            = "${var.project}-frontend"
  image           = "mendhak/http-https-echo:latest"
  port            = 8080
  service_account = module.sa_frontend.email
  ingress         = "INGRESS_TRAFFIC_ALL"
  allow_public    = true

  env_vars = {
    BACKEND_URL = module.backend.url
  }

  vpc_access = null

  depends_on = [google_project_service.apis]
}

# --- IAM: Frontend SA can invoke the backend ---
resource "google_cloud_run_v2_service_iam_member" "frontend_invokes_backend" {
  project  = var.project_id
  location = var.region
  name     = module.backend.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.sa_frontend.email}"
}
