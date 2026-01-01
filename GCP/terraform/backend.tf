########################################
# Enable required APIs (safe, idempotent)
########################################

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
}

########################################
# NOTE: Firestore DATABASE CREATION REMOVED
########################################
# Firestore (default database) already exists in this project.
# Terraform MUST NOT attempt to create it again.
# Leaving the API enabled is sufficient.

########################################
# Service Account for Cloud Run
########################################

resource "google_service_account" "counter_sa" {
  account_id   = "visitor-counter-sa"
  display_name = "Visitor Counter Cloud Run SA"
}

# Allow SA to read/write Firestore
resource "google_project_iam_member" "counter_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.counter_sa.email}"
}

########################################
# Cloud Run service (cost-safe)
########################################

resource "google_cloud_run_v2_service" "visitor_counter" {
  name                = "visitor-counter"
  location            = var.run_location
  deletion_protection = false

  template {
    service_account = google_service_account.counter_sa.email

    containers {
      # MUST match Artifact Registry image exactly
      image = var.counter_image

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

      # IMPORTANT: CORS origin must match the exact frontend origin you use
      # Your canonical site URL is https://www.cloudwithzarapalevani.site
      env {
        name  = "ALLOWED_ORIGIN"
        value = "https://www.cloudwithzarapalevani.site"
      }

      env {
        name  = "COUNTER_DOC"
        value = "site/visitorCounter"
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  depends_on = [
    google_project_service.run,
    google_project_service.firestore
  ]
}

########################################
# Public access (browser calls)
########################################

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  location = google_cloud_run_v2_service.visitor_counter.location
  name     = google_cloud_run_v2_service.visitor_counter.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

########################################
# Outputs
########################################

output "visitor_counter_url" {
  value = google_cloud_run_v2_service.visitor_counter.uri
}
