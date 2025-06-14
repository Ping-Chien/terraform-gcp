resource "google_sql_database_instance" "default" {
  name             = "tracing"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro" # 省錢機型
    disk_size = 10       # 最小磁碟空間（GB）
    disk_autoresize = false
    activation_policy = "ALWAYS"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.tracing-vpc.id
    }
  }
}

resource "google_sql_database" "counter" {
  name     = "counter"
  instance = google_sql_database_instance.default.name

  depends_on = [google_sql_database_instance.default]
}

resource "google_sql_user" "root" {
  name     = "postgres"
  instance = google_sql_database_instance.default.name
  password = var.db_password
  depends_on = [google_sql_database_instance.default]
}

resource "google_sql_database" "dotnet" {
  name     = "dotnet"
  instance = google_sql_database_instance.default.name

  depends_on = [google_sql_database_instance.default]
}

resource "google_sql_user" "dotnet" {
  name     = "dotnet"
  instance = google_sql_database_instance.default.name
  password = var.dotnet_password
  depends_on = [google_sql_database_instance.default]
}

# 連線mysql時，還是要在terminal輸入密碼，不接受指令帶入
/*resource "null_resource" "init_cloudsql_schema" {
  provisioner "local-exec" {
    command = <<EOT
      MYSQL_PWD=${var.db_password} gcloud sql connect ${google_sql_database_instance.default.name} \
        --user=root \
        --project=${var.project_id} \
        --quiet < ${path.module}/cloudsql-init.sql
    EOT
    environment = {
      CLOUDSDK_CORE_PROJECT = var.project_id
    }
  }
}
*/
