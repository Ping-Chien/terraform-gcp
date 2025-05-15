variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "cloud-sre-poc-447001"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-east1"
}

variable "db_password" {
  description = "Cloud SQL root user password"
  type        = string
  sensitive   = true
  default     = "root"
}

variable "gcp_credentials_file" {
  description = "Path to GCP credentials json file"
  type        = string
  default     = ".config/gcloud/cloud-sre-poc-447001-5ee27f179112.json"
}
