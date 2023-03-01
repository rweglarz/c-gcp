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

provider "panos" {
  json_config_file = "panorama_creds.json"
}
