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
