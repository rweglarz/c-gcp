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

resource "random_id" "this" {
  byte_length = 5
}
