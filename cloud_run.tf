/**
 * cloud_run.tf - 部署帶有k6的Cloud Run服務，用於對GKE pods進行壓力測試
 */

# 為Cloud Run服務創建服務帳號
resource "google_service_account" "k6_service_account" {
  project      = var.project_id
  account_id   = "k6-cloud-run-sa"
  display_name = "K6 Load Testing Service Account"
  description  = "Cloud Run使用的服務帳號，用於在GKE pods上執行k6負載測試"
}

# 為服務帳號授予必要的權限
resource "google_project_iam_member" "k6_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.k6_service_account.email}"
}

resource "google_project_iam_member" "k6_metrics_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.k6_service_account.email}"
}

resource "google_project_iam_member" "k6_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.k6_service_account.email}"
}

# VPC連接器 - 連接到現有的tracing-vpc
# 將此資源放在前面優先部署
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector"
  region        = var.region
  project       = var.project_id
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.tracing-vpc.name
  # 設定最小吞吐量 (Mbps) - 必須是100的倍數且介於200和1000之間
  min_throughput = 200
  max_throughput = 300
  # 依賴於現有VPC
  depends_on    = [google_compute_network.tracing-vpc]
}

# 用於執行k6負載測試的Cloud Run服務
# 調整為依賴於VPC連接器後部署
resource "google_cloud_run_service" "k6_service" {
  name     = "k6-load-test"
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        # 改用帶有 HTTP 服務器的 Docker 映像
        image = "loadimpact/k6:latest"
        
        # 指定啟動命令，使用 nc 工具來啟動一個簡單的 HTTP 服務
        command = ["/bin/sh"]
        args = [
          "-c", 
          "echo 'HTTP/1.1 200 OK\nContent-Type: text/plain\n\nK6 Load Test Service Ready' | nc -l -p 8080"
        ]
        
        # 確保 Cloud Run 知道我們的容器在正確的端口上運行
        ports {
          container_port = 8080
        }
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
        
        # k6配置的環境變數
        env {
          name  = "K6_OUT"
          value = "json=/tmp/k6-results.json"
        }
        
        # 將JSON結果輸出到日誌
        env {
          name  = "K6_JSON_OUTPUT_SCRIPT"
          value = "console.log(JSON.stringify(data));"
        }

        # Cloud Run 會自動設置 PORT 環境變數，所以我們不需要手動設置
        
      }
      
      # Cloud Run服務的服務帳號
      service_account_name = google_service_account.k6_service_account.email
      
      
      # 設置容器並發數
      container_concurrency = 10
      
      # 設置服務超時時間
      timeout_seconds = 900
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"
        "autoscaling.knative.dev/maxScale" = "10"
        # 允許連接到GKE集群
        "run.googleapis.com/vpc-access-connector" = "projects/${var.project_id}/locations/${var.region}/connectors/vpc-connector"
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
        # 設置 ingress 為 all，允許從任何來源訪問
        "run.googleapis.com/ingress" = "all"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # 依賴於服務帳號、IAM綁定和VPC連接器
  depends_on = [
    google_service_account.k6_service_account,
    google_project_iam_member.k6_gke_developer,
    google_project_iam_member.k6_metrics_writer,
    google_project_iam_member.k6_log_writer,
    google_vpc_access_connector.connector  # 確保VPC連接器先完成部署
  ]
}

# 對 Cloud Run 服務設置訪問權限，允許特定 Google 帳號訪問

# 變量：用於存儲允許訪問的 Google 帳號郵箱
variable "allowed_user_email" {
  description = "允許訪問 Cloud Run 服務的 Google 帳號郵箱"
  type        = string
  default     = "" # 請在 terraform.tfvars 中設置您的郵箱
}

# 將 IAM 策略添加到 Cloud Run 服務，允許所有用戶訪問 (包括未認證的用戶)
resource "google_cloud_run_service_iam_member" "alluser_access" {
  location = google_cloud_run_service.k6_service.location
  project  = var.project_id
  service  = google_cloud_run_service.k6_service.name
  role     = "roles/run.invoker"
  # 允許所有用戶訪問，包括未認證的用戶
  member   = "allUsers"
}

# 以下保留原設置以便需要時可以恢復
# # 將 IAM 策略添加到 Cloud Run 服務，允許特定用戶訪問
# resource "google_cloud_run_service_iam_member" "user_access" {
#   location = google_cloud_run_service.k6_service.location
#   project  = var.project_id
#   service  = google_cloud_run_service.k6_service.name
#   role     = "roles/run.invoker"
#   # 使用用戶 Google 帳號訪問
#   member   = "user:${var.allowed_user_email}"
# }


