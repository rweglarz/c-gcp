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
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~> 1.11"
    }
    google = {
      version = "~> 7.0"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}

resource "panos_vm_auth_key" "this" {
  hours = 24*30*6

  lifecycle { create_before_destroy = true }
}
