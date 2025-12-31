########################################
# Providers
########################################

provider "google" {
  project     = var.project_id
  credentials = var.gcp_credentials_json
}

provider "cloudflare" {
  # Token is picked up from CLOUDFLARE_API_TOKEN (Terraform Cloud env var)
}

########################################
# GCS Static Website Bucket
########################################

resource "google_storage_bucket" "site" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
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
# Cloudflare DNS
########################################

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone_name
}

resource "cloudflare_record" "apex" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "CNAME"
  content = "${var.bucket_name}.storage.googleapis.com"
  proxied = true
  ttl     = 1

  allow_overwrite = true
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "www"
  type    = "CNAME"
  content = "${var.bucket_name}.storage.googleapis.com"
  proxied = true
  ttl     = 1

  allow_overwrite = true
}
