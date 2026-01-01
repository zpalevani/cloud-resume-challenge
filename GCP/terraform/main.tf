########################################
# Providers
########################################

provider "google" {
  project     = var.project_id
  credentials = var.gcp_credentials_json
}

provider "cloudflare" {
  # Uses CLOUDFLARE_API_TOKEN from your environment
}

########################################
# GCS Static Bucket (objects only)
########################################

resource "google_storage_bucket" "site" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true
}

########################################
# Public Read Access (objects)
########################################

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

########################################
# Upload site files to the bucket
########################################

locals {
  site_dir = "${path.module}/../site"
  files    = fileset(local.site_dir, "**")
}

resource "google_storage_bucket_object" "site_files" {
  for_each = { for f in local.files : f => f }

  name   = each.value
  bucket = google_storage_bucket.site.name
  source = "${local.site_dir}/${each.value}"

  # Cache assets; keep HTML no-cache for iteration
  cache_control = startswith(each.value, "assets/") ? "public, max-age=86400" : "no-cache"
}

########################################
# Cloudflare DNS (point to Worker)
########################################

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone_name
}

resource "cloudflare_record" "apex" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "CNAME"
  content = var.worker_hostname
  proxied = true
  ttl     = 1

  allow_overwrite = true
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "www"
  type    = "CNAME"
  content = var.worker_hostname
  proxied = true
  ttl     = 1

  allow_overwrite = true
}
