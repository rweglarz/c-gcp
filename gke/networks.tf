
resource "google_compute_network" "gke" {
  name                    = "${var.name}-gke"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "gke" {
  name          = "${var.name}-gke"
  ip_cidr_range = var.cidr
  network       = google_compute_network.gke.id
}
