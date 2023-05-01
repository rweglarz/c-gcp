provider "google" {
  region  = var.region
  project = var.project
  zone    = var.zone
}
provider "google-beta" {
  region  = var.region
  project = var.project
  zone    = var.zone
}
