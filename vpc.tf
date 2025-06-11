# 建立 VPC Network
resource "google_compute_network" "tracing-vpc" {
  name                    = "tracing-vpc"
  auto_create_subnetworks = true
}

# 創建 Cloud Router 用於 NAT Gateway
resource "google_compute_router" "router" {
  name    = "tracing-router"
  region  = var.region
  network = google_compute_network.tracing-vpc.id
}

# 創建 Cloud NAT 以允許私有 GKE 節點訪問互聯網
resource "google_compute_router_nat" "nat" {
  name                               = "tracing-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 建立 Private Service Connection
resource "google_compute_global_address" "private_ip_address" {
  name          = "tracing-psc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.tracing-vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.tracing-vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# 允許 GKE 節點連線到 Cloud SQL 3306 port
resource "google_compute_firewall" "allow_gke_to_cloudsql_mysql" {
  name    = "allow-gke-to-cloudsql-mysql"
  network = google_compute_network.tracing-vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges      = ["0.0.0.0/0"]  # GKE 節點 subnet CIDR，請依實際調整
  destination_ranges = ["0.0.0.0/0"]  # Cloud SQL subnet CIDR，請依實際調整

  description = "Allow GKE nodes to access Cloud SQL MySQL over private IP"
  priority    = 1000
  direction   = "INGRESS"
}

# 允許 GKE 節點連線到 Cloud SQL 5432 port (PostgreSQL)
resource "google_compute_firewall" "allow_gke_to_cloudsql_postgres" {
  name    = "allow-gke-to-cloudsql-postgres"
  network = google_compute_network.tracing-vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges      = ["0.0.0.0/0"]  # GKE 節點 subnet CIDR，請依實際調整
  destination_ranges = ["0.0.0.0/0"]  # Cloud SQL subnet CIDR，請依實際調整

  description = "Allow GKE nodes to access Cloud SQL PostgreSQL over private IP"
  priority    = 1000
  direction   = "INGRESS"
}
