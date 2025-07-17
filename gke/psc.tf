resource "google_compute_address" "psc" {
  count = var.psc_attachment!=null ? 1 : 0

  name         = "${var.name}-psc-endpoint"
  region       = var.region
  subnetwork   = google_compute_subnetwork.gke.id
  address_type = "INTERNAL"
  address      = cidrhost(google_compute_subnetwork.gke.ip_cidr_range, 10)
}

resource "google_compute_forwarding_rule" "psc_consumer" {
  count = var.psc_attachment!=null ? 1 : 0

  name                    = "${var.name}-psc-consumer"
  region                  = var.region
  network                 = google_compute_network.gke.id
  ip_address              = google_compute_address.psc[0].self_link
  target                  = var.psc_attachment
  load_balancing_scheme   = "" # Explicit empty string required for PSC
}
