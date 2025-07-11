variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "cloud-sre-poc-465509"
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

variable "dotnet_password" {
  description = "Cloud SQL root user password"
  type        = string
  sensitive   = true
  default     = "1qaz@WSX"
}

variable "gcp_credentials_file" {
  description = "Path to GCP credentials json file"
  type        = string
  default     = ".config/gcloud/cloud-sre-poc-465509-90134ef8cb5d.json"
}
