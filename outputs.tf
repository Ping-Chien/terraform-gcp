output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "cloudsql_instance_name" {
  value = google_sql_database_instance.default.name
}

output "cloudsql_database_name" {
  value = google_sql_database.counter.name
}

