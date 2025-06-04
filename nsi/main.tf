data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

provider "google" {
  region                          = "europe-west1"
  zone                            = "europe-west1-b"
  project                         = var.gcp_project_producer
  add_terraform_attribution_label = false
}
provider "google-beta" {
  region                          = "europe-west1"
  zone                            = "europe-west1-b"
  project                         = var.gcp_project_producer
  add_terraform_attribution_label = false
}

provider "google" {
  alias                           = "consumer"
  region                          = "europe-west1"
  zone                            = "europe-west1-b"
  project                         = var.gcp_project_consumer
  add_terraform_attribution_label = false
  credentials                     = var.consumer_sa
}

provider "google" {
  # used to create endpoint from producer user
  alias                           = "consumerp"
  region                          = "europe-west1"
  zone                            = "europe-west1-b"
  project                         = var.gcp_project_consumer
  add_terraform_attribution_label = false
}

data "google_compute_zones" "this" {
}

terraform {
  required_providers {
    panos = {
      source  = "PaloAltoNetworks/panos"
      version = "~> 1.0, < 2.0"
      # version = "2.0.0"
    }
    google = {
      version = "~> 6.9"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
  # auth_file = "panorama_creds.json"
  # skip_verify_certificate = true
}

resource "random_id" "this" {
  byte_length = 5
}

resource "panos_vm_auth_key" "this" {
  hours = 24 * 30 * 6
}
# ephemeral "panos_vm_auth_key" "this" {
#   lifetime = 24*30
# }
