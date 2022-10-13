
resource "google_compute_network" "gke" {
  name                    = "${var.name}-gke"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "gke" {
  name          = "${var.name}-gke"
  ip_cidr_range = var.cidr
  network       = google_compute_network.gke.id
}

resource "google_compute_address" "nat" {
  name   = "${var.name}-nat"
  region = var.region
}

resource "google_compute_router" "gke" {
  name    = "${var.name}-rtr-data"
  network = google_compute_network.gke.id
}

resource "google_compute_router_nat" "gke" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.gke.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [
    google_compute_address.nat.self_link
  ]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
