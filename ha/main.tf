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
    }
    google = {
      version = "~> 6.9"
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
