# 建立 VPC Network
resource "google_compute_network" "tracing-vpc" {
  name                    = "tracing-vpc"
  auto_create_subnetworks = true
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
resource "google_compute_firewall" "allow_gke_to_cloudsql" {
  name    = "allow-gke-to-cloudsql"
  network = google_compute_network.tracing-vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges      = ["10.0.0.0/16"]  # GKE 節點 subnet CIDR，請依實際調整
  destination_ranges = ["10.0.0.0/24"]  # Cloud SQL subnet CIDR，請依實際調整

  description = "Allow GKE nodes to access Cloud SQL over private IP"
  priority    = 1000
  direction   = "INGRESS"
}

