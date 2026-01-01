resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = true
}

resource "google_artifact_registry_repository" "visitor_counter" {
  project       = var.project_id
  location      = var.run_location
  repository_id = "visitor-counter"
  description   = "Docker repo for visitor counter service"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}
