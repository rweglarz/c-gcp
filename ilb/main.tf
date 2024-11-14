provider "google" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = var.gcp_project
}
provider "google-beta" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = var.gcp_project
}

terraform {
  required_providers {
    google = {
      version = "~> 6.9"
    }
  }
}

resource "random_id" "this" {
  byte_length = 5
}
