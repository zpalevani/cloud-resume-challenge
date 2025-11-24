provider "google" {
  project = "cloud-resume-challenge-479115"
  region  = "us-east1"
}

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

# Backend bucket for the HTTPS load balancer
resource "google_compute_backend_bucket" "static_site_backend" {
  name        = "cloudwith-backend-bucket"               # must match the name in GCP
  bucket_name = google_storage_bucket.static-site.name   # your GCS bucket
  enable_cdn  = true                                     # you enabled Cloud CDN

  # Safety: don't let Terraform delete this by mistake
  lifecycle {
    prevent_destroy = true
  }
}

# Google-managed SSL certificate for cloudwith.zarapalevani.com
resource "google_compute_managed_ssl_certificate" "static_site_cert" {
  name = "cloudwith-cert"   # must match the cert name in GCP

  managed {
    # You can hardcode or use a variable; hardcoding is fine for this project
    domains = ["cloudwith.zarapalevani.com"]
  }

  lifecycle {
    prevent_destroy = true
  }
}


# Upload index.html
resource "google_storage_bucket_object" "index" {
  name         = "index.html"
  bucket       = google_storage_bucket.static-site.name
  source       = "${path.module}/site/index.html"
  content_type = "text/html"
}

resource "google_storage_bucket_object" "not_found" {
  name         = "404.html"
  bucket       = google_storage_bucket.static-site.name
  source       = "${path.module}/site/404.html"
  content_type = "text/html"
}

