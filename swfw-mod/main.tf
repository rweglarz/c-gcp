provider "google" {
  region  = var.region
  project = var.project
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

terraform {
  required_providers {
    google = {
      version = "~>6.8"
    }
  }
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}
