resource "google_artifact_registry_repository" "app_repo" {
  provider      = google
  location      = var.region
  repository_id = "app-image-repo"
  description   = "App image repository"
  format        = "DOCKER"
}
