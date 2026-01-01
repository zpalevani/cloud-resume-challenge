########################################
# GCP
########################################

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "location" {
  type        = string
  description = "GCS bucket location"
  default     = "US"
}

variable "bucket_name" {
  type        = string
  description = "Unique GCS bucket name (NOT the domain name)"
}

# Optional: only needed if you run Terraform via Terraform Cloud
# and inject credentials as a sensitive variable.
# In Codespaces we authenticate via GOOGLE_APPLICATION_CREDENTIALS instead.
variable "gcp_credentials_json" {
  description = "GCP service account key JSON (Terraform Cloud). Not used in Codespaces auth flow."
  type        = string
  sensitive   = true
  default     = ""
}

########################################
# Cloudflare
########################################

variable "cloudflare_zone_name" {
  type        = string
  description = "Cloudflare zone name (your domain), e.g. cloudwithzarapalevani.site"
}

variable "site_hostname" {
  type        = string
  description = "Public hostname for the site (your domain), e.g. cloudwithzarapalevani.site"
}

# Worker hostname that the DNS records should point to
# Example: cloudresume-cloudwithzarapalevanisitegcp.zpalevani.workers.dev
variable "worker_hostname" {
  type        = string
  description = "Cloudflare Worker hostname (workers.dev) used as the DNS target"
}

variable "create_www_redirect" {
  type        = bool
  description = "Whether to create www → apex redirect (not used when both apex and www point to the worker)"
  default     = false
}

########################################
# Phase 2: Visitor Counter (Cloud Run + Firestore)
########################################

variable "run_location" {
  type        = string
  description = "Cloud Run region"
  default     = "us-central1"
}

variable "firestore_location" {
  type        = string
  description = "Firestore location (multi-region). Common: nam5 (North America)."
  default     = "nam5"
}

variable "counter_image" {
  type        = string
  description = "Container image URI for visitor counter (Artifact Registry)"
}
