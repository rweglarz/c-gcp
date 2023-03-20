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
  }
}

data "google_compute_zones" "available" {
  for_each = var.networks["mgmt"]
  region   = each.key
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}
