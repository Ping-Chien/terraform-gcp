resource "google_service_account" "otel_sa" {
  account_id   = "otel-collector" # 這會產生 otel-svc-account@PROJECT_ID.iam.gserviceaccount.com
  display_name = "OpenTelemetry Service Account"
}

resource "google_project_iam_member" "otel_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.otel_sa.email}"
}

resource "google_project_iam_member" "otel_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.otel_sa.email}"
}

resource "google_project_iam_member" "otel_tracing" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.otel_sa.email}"
}

resource "google_service_account" "dotnet_sa" {
  account_id   = "dotnet-backend"
  display_name = "dotnet-backend Service Account"
}

resource "google_service_account" "dotnet_frontend_sa" {
  account_id   = "dotnet-frontend"
  display_name = "dotnet-frontend Service Account"
}

resource "google_project_iam_member" "dotnet_cloud_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.dotnet_sa.email}"
}



