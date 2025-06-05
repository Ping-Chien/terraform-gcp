output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "cloudsql_instance_name" {
  value = google_sql_database_instance.default.name
}

output "cloudsql_database_name" {
  value = google_sql_database.counter.name
}

# Cloud Run k6 輸出值
output "cloud_run_url" {
  value       = google_cloud_run_service.k6_service.status[0].url
  description = "已部署Cloud Run服務的URL"
}

output "k6_service_account" {
  value       = google_service_account.k6_service_account.email
  description = "Cloud Run服務使用的服務帳號電子郵件"
}

