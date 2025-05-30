# 1. 建立 GCP Service Account
resource "google_service_account" "k8s_default" {
  account_id   = "k8s-default"
  display_name = "K8s Default Service Account for GKE"
  project      = var.project_id
}

# 2. 賦予 Artifact Registry Reader 權限
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.k8s_default.email}"
}

# 授權 GKE Autopilot 預設 Service Account Artifact Registry Reader 權限
resource "google_project_iam_member" "autopilot_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:11269261557-compute@developer.gserviceaccount.com"
}

# 3. Workload Identity 綁定 K8s default ServiceAccount
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.k8s_default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/default]"
}

resource "google_container_cluster" "primary" {
  name     = "tracing-gke-cluster"
  location = var.region
  enable_autopilot = true
  deletion_protection = false
  network    = google_compute_network.tracing-vpc.id

  # 私有集群設定 
  private_cluster_config { 
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "private"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

/* for Cloud SQL Proxy

本區塊說明如何為 GKE 應用自動化產生 Cloud SQL Proxy 所需的 Service Account 金鑰。

步驟與注意事項：
1. 建立專用 Service Account
   - 專門給 Cloud SQL Proxy 使用，避免與其他服務共用權限。
2. 給予 cloudsql.client 權限
   - 讓此 Service Account 能連線並代理 Cloud SQL。
3. 建立 Service Account Key
   - 產生金鑰 (JSON) 給 Cloud SQL Proxy 使用。
4. 將金鑰寫入本地檔案
   - 寫到 config/cloudsql 目錄，供 Proxy 掛載。
*/

# 1. 建立專用 Service Account
resource "google_service_account" "cloudsql_sa" {
  account_id   = "cloudsql-proxy-sa"
  display_name = "Cloud SQL Proxy Service Account"
}

# 2. 給予 cloudsql.client 權限
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_sa.email}"
}

# 3. 建立 Service Account Key
resource "google_service_account_key" "cloudsql_sa_key" {
  service_account_id = google_service_account.cloudsql_sa.name
}

# 4. 建立 Kubernetes Secret（需有 Kubernetes provider 設定）
#
# 總結說明：
# - 此步驟產生的 Secret，會直接建立在你指定的 GKE（Kubernetes）叢集的 default namespace。
# - Secret 名稱為 cloudsql-sa-key，內容是 Service Account 的 private key（base64 編碼，key 名為 credentials.json）。
# - 只有在 GKE 叢集內、default namespace 中的 Pod 掛載這個 Secret，才可取得金鑰存取 Cloud SQL。
# - Secret 內容不會存在本地或 GCP Secret Manager，只會存在 GKE 叢集內。
# - 你可用 kubectl get secret cloudsql-sa-key -o yaml 查詢 Secret 內容（內容為 base64 編碼）。
# - 這是 Kubernetes 原生 Secret，Deployment 可直接掛載使用。
resource "local_file" "cloudsql_sa_key_json" {
  content  = base64decode(google_service_account_key.cloudsql_sa_key.private_key)
  filename = "${path.module}/.config/cloudsql/cloudsql-sa-key.json"
}
