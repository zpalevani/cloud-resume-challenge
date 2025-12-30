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

variable "create_www_redirect" {
  type        = bool
  description = "Whether to create www → apex redirect"
  default     = true
}
