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
    database_flags {
      name  = "max_connections"
      value = "200"  # 調整為所需的連接數
    }
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.tracing-vpc.id
    }
  }

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
      settings[0].pricing_plan,
      settings[0].backup_configuration,
    ]
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
