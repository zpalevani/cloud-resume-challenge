terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "zarapalevani-org"

    workspaces {
      name = "gcs-zaracloudresume-gcp"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
