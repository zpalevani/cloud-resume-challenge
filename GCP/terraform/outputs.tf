output "bucket_name" {
  value = google_storage_bucket.site.name
}

output "gcs_website_url" {
  value = "http://${google_storage_bucket.site.name}.storage.googleapis.com"
}

output "cloudflare_zone_id" {
  value = data.cloudflare_zone.zone.id
}
