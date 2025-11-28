provider "google" {
  project = "cloud-resume-challenge-479115"
  region  = "us-east1"
}

# --- Local Configuration Map for Files (UPDATED) ---
# Removed AWS and Azure entries to match your screenshot
locals {
  static_site_files = {
    "index.html"        = "${path.module}/site/index.html"
    "404.html"          = "${path.module}/site/404.html"

    # Clean URL Pages (folder/index.html convention)
    "blog/index.html"   = "${path.module}/site/blog/index.html"
    "resume/index.html" = "${path.module}/site/resume/index.html"
    "gcp/index.html"    = "${path.module}/site/gcp/index.html"
    
    # Static Assets
    "css/style.css"     = "${path.module}/site/css/style.css"
  }
}

# --- Core GCS Bucket Configuration ---
resource "google_storage_bucket" "static-site" {
  name          = var.bucket_name
  location      = "us-east1"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Make all objects publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.static-site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# --- Cloud Load Balancer/CDN Configuration ---
# Backend bucket for the HTTPS load balancer
resource "google_compute_backend_bucket" "static_site_backend" {
  name        = "cloudwith-backend-bucket"             # must match the name in GCP
  bucket_name = google_storage_bucket.static-site.name # your GCS bucket
  enable_cdn  = true                                   # Cloud CDN enabled

  # Safety: don't let Terraform delete this by mistake
  lifecycle {
    prevent_destroy = true
  }
}

# Google-managed SSL certificate for cloudwith.zarapalevani.com
resource "google_compute_managed_ssl_certificate" "static_site_cert" {
  name = "cloudwith-cert" # must match the cert name in GCP

  managed {
    domains = ["cloudwith.zarapalevani.com"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

# --- Website File Deployment ---
# This iterates over the 'static_site_files' map to upload assets.
resource "google_storage_bucket_object" "site_objects" {
  for_each = local.static_site_files
  
  # The GCS object name (key) dictates the clean URL structure
  name         = each.key 
  bucket       = google_storage_bucket.static-site.name
  
  # The source on your filesystem (value)
  source       = each.value 
  
  # Use a ternary operator to set the correct content type
  content_type = endswith(each.key, ".css") ? "text/css" : "text/html"
}