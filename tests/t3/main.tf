provider "google" {
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


data "google_compute_zones" "this" {
  region = var.region
}
