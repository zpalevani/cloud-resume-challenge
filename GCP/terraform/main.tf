########################################
# Providers
########################################

provider "google" {
  project = var.project_id
}

provider "cloudflare" {
  # Token is picked up from CLOUDFLARE_API_TOKEN env var
}

########################################
# Locals for MIME Types & Files
########################################

locals {
  site_dir = "${path.module}/../site"
  files    = fileset(local.site_dir, "**")

  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".json" = "application/json"
    ".txt"  = "text/plain"
  }
}

########################################
# GCS Static Website Bucket
########################################

resource "google_storage_bucket" "site" {
  # IMPORTANT: bucket name should be a UNIQUE bucket name (NOT the domain)
  # Example: cloudwithzarapalevani-site
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
# Upload site files to the bucket
########################################

resource "google_storage_bucket_object" "site_files" {
  for_each = { for f in local.files : f => f }

  name   = each.value
  bucket = google_storage_bucket.site.name
  source = "${local.site_dir}/${each.value}"

  content_type = lookup(
    local.mime_types,
    regex("\\.[^.]+$", each.value),
    "application/octet-stream"
  )

  cache_control = (
    endswith(each.value, ".html")
    ? "no-cache"
    : "public, max-age=86400"
  )
}

########################################
# Cloudflare DNS
########################################

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone_name
}

# Apex record: cloudwithzarapalevani.site -> bucket endpoint
resource "cloudflare_record" "apex" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "CNAME"
  content = "${var.bucket_name}.storage.googleapis.com"
  proxied = true
  ttl     = 1

  # Optional, but helps if a record already exists
  allow_overwrite = true
}

# www record: www.cloudwithzarapalevani.site -> bucket endpoint
resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "www"
  type    = "CNAME"
  content = "${var.bucket_name}.storage.googleapis.com"
  proxied = true
  ttl     = 1

  # ✅ This is the fix for your “already exists” error
  allow_overwrite = true
}
