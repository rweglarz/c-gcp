data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

data "google_compute_zones" "this" {
  for_each = toset(local.regions)
  region   = each.key
}


provider "google" {
  region  = var.region
  project = var.project
  add_terraform_attribution_label = false
}
provider "google-beta" {
  region  = var.region
  project = var.project
  add_terraform_attribution_label = false
}

terraform {
  required_providers {
    google = {
      version = "~> 6.9"
    }
  }
}
