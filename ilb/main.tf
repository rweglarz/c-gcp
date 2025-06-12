data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

provider "google" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = var.gcp_project
  add_terraform_attribution_label = false
}
provider "google-beta" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = var.gcp_project
  add_terraform_attribution_label = false
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
    google = {
      version = "~> 6.9"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}

resource "random_id" "this" {
  byte_length = 5
}


resource "panos_vm_auth_key" "this" {
  hours = 24*30*6
  lifecycle { create_before_destroy = true }
}
