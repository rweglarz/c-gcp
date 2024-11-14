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
