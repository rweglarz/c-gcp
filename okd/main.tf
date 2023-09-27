provider "google" {
  region  = var.region
  project = var.project
}

provider "google-beta" {
  region  = var.region
  project = var.project
}
