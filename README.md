# 3-Tier Application Infrastructure on Google Cloud

A Terraform project that defines infrastructure for a simple 3-tier application using Google Cloud Platform.

## Architecture

This project implements the classic 3-tier model - presentation, application, and data - using Google Cloud's serverless and managed services.

```
              +------------------+
              |    Internet      |
              +--------+---------+
                       |
                       v
              +------------------+
              | Frontend (T1)    |
              | Cloud Run        |
              | Public access    |
              +--------+---------+
                       |
                       | HTTPS + IAM auth
                       v
              +------------------+     +--------------+
              | Backend (T2)     |     | VPC          |
              | Cloud Run        +---->| Direct VPC   |
              | Internal only    |     | Egress       |
              +------------------+     +------+-------+
                                              |
                                              | Private IP
                                              v
                                       +--------------+
                                       | Cloud SQL    |
                                       | (T3)         |
                                       | PostgreSQL 16|
                                       | Private IP   |
                                       | only         |
                                       +--------------+
```

## Three Tiers

| Tier         | Role                 | GCP Resource            | Image                     | Access            |
| ------------ | -------------------- | ----------------------- | ------------------------- | ----------------- |
| Presentation | Frontend echo server | Cloud Run               | `mendhak/http-https-echo` | **Public**        |
| Application  | Backend echo server  | Cloud Run               | `mendhak/http-https-echo` | **Internal only** |
| Data         | Persistent storage   | Cloud SQL PostgreSQL 16 | -                         | **Private IP**    |

### Tier 1 - Presentation (Frontend)

A Cloud Run service accepting public internet traffic. It communicates with the backend over HTTPS using the backend's Cloud Run URL, authenticated via IAM (the frontend's service account holds the `roles/run.invoker` role on the backend service).

### Tier 2 - Application (Backend)

A Cloud Run service configured for internal-only ingress. It connects to Cloud SQL over a private IP using Direct VPC Egress through a dedicated subnet. No public traffic can reach this service directly.

### Tier 3 - Data (Database)

A Cloud SQL PostgreSQL 16 instance with a private IP only, accessible through VPC peering (Private Services Access). A scoped firewall rule permits egress from Cloud Run (tagged instances) to the database on port 5432.

## Design Decisions

### Why Cloud Run instead of VMs or GKE

Cloud Run was chosen to keep the project focused and small, as the assignment requests. It provides a clear separation of tiers without the overhead of managing VMs, instance groups, load balancers, or a Kubernetes cluster. Each tier is an independently deployable, scalable unit, which is the core goal of a 3-tier architecture.

### Frontend-to-backend communication

In a traditional VM-based 3-tier setup, the frontend and backend would sit in separate subnets connected by internal network routes and firewalls. Here, the frontend communicates with the backend over its Cloud Run URL using IAM-based authentication rather than network-level isolation. This is the idiomatic pattern for Cloud Run service-to-service communication on GCP. The backend is set to internal-only ingress, so it cannot be reached by arbitrary external traffic, only by services within the same GCP project or VPC, and only with the correct IAM permissions.

### Network design

A custom VPC is created with a single subnet for Cloud Run's Direct VPC Egress. Private Services Access is configured to give Cloud SQL a private IP on the VPC, and a firewall rule scopes egress from Cloud Run to the database port (5432). The frontend does not use VPC access since it only needs to reach the backend's HTTPS endpoint, not any private network resources.

### Module structure

The project is organized into reusable modules:

- `modules/network` - VPC, subnet, Private Services Access, firewall rules
- `modules/service-account` - service account creation with configurable project-level roles
- `modules/database` - Cloud SQL instance, database, and user
- `modules/cloud-run` - Cloud Run v2 service with configurable networking, scaling, and environment

This keeps the root module readable and makes each component independently testable.

## Assumptions and Simplifications

A typical 3-tier architecture places each tier on dedicated compute within its own network segment, with firewalls enforcing strict directional traffic flow between them (presentation → application → data). This project maps that model onto GCP's serverless primitives, which changes how some of those concerns are addressed.

| Area                   | Typical 3-Tier                                                                                       | This Project                                                                                                                                                                                           |
| ---------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Compute**            | VMs or containers in managed groups behind load balancers at each tier.                              | Cloud Run serverless containers. No VMs, instance groups, or load balancers to manage. Scale-to-zero with max 1 instance.                                                                              |
| **Tier isolation**     | Each tier in its own subnet with firewall rules enforcing directional flow. No tier can be bypassed. | Backend is internal-only and reachable only by holders of `roles/run.invoker`. The frontend has no VPC attachment, it reaches the backend over HTTPS + IAM rather than through network-layer controls. |
| **Presentation layer** | Sits behind a load balancer handling TLS termination, routing, and ingress control.                  | Exposed directly via Cloud Run's managed URL with Google-managed TLS. No dedicated load balancer, CDN, or WAF.                                                                                         |
| **Data layer**         | Managed database with right-sized compute, high availability, and automated backups.                 | Cloud SQL PostgreSQL 16 with a minimal instance (`db-f1-micro`, zonal, HDD, 10 GB fixed). Private IP only, accessed via VPC peering.                                                                   |
| **Secrets**            | Credentials stored in a secrets manager and injected at runtime.                                     | Database password passed as a Terraform variable. Visible in state files.                                                                                                                              |
| **Observability**      | Logging, monitoring, and alerting integrated across tiers.                                           | None configured. Out of scope per the assignment.                                                                                                                                                      |
| **CI/CD**              | Automated build and deployment pipeline for each tier.                                               | Placeholder container images (`mendhak/http-https-echo`). No pipeline. Out of scope per the assignment.                                                                                                |

The core 3-tier separation - independent presentation, application, and data layers with controlled communication between them — is preserved. The implementation uses IAM and Cloud Run's ingress controls where a traditional deployment would use subnets and firewalls.

## Project Structure

```

.
├── README.md
├── main.tf # Root - composes all modules
├── variables.tf # Input variables
├── outputs.tf # Output values
├── providers.tf # Provider config + remote backend + API enablement
│
├── bootstrap/
│ └── main.tf # One-time: creates GCS state bucket
│
└── modules/
├── network/
│ ├── main.tf # VPC, subnets, Private Services Access, firewall
│ ├── variables.tf
│ └── outputs.tf
│
├── service-account/
│ ├── main.tf # SA creation + IAM role bindings
│ ├── variables.tf
│ └── outputs.tf
│
├── cloud-run/
│ ├── main.tf # Single generic Cloud Run service
│ ├── variables.tf
│ └── outputs.tf
│
└── database/
├── main.tf # Cloud SQL instance + database + user
├── variables.tf
└── outputs.tf

```

## How to Run

### Step 1: Bootstrap the state bucket (one-time)

The `bootstrap/` directory creates a GCS bucket for Terraform remote state.

```bash
cd bootstrap
terraform init
terraform apply -var="project_id=my-gcp-project"

# Note the bucket name from the output
terraform output bucket_name
```

Then update `providers.tf` with the newly created bucket name.

### Step 2: Deploy the infrastructure

```bash
cd ..   # back to root

# 1. Authenticate with gcloud

# 2. Initialize (connects to remote state)
terraform init

# 3. Plan
terraform plan \
  -var="project_id=my-gcp-project" \
  -var="db_password=YourSecureP@ss123!"

# 4. Apply
terraform apply \
  -var="project_id=my-gcp-project" \
  -var="db_password=YourSecureP@ss123!"
```

## Cleanup

```bash
terraform destroy \
  -var="project_id=my-gcp-project" \
  -var="db_password=YourSecureP@ss123!"
```
