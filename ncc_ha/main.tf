provider "google" {
  region  = var.region
  zone    = var.zone
  project = var.project
}
provider "google-beta" {
  region  = var.region
  zone    = var.zone
  project = var.project
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}
