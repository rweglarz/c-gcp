resource "google_compute_firewall" "panorama" {
  name      = "lab-${var.name}-panorama-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = concat(
    [
      "${google_compute_address.cloud_nat.address}/32"
    ],
  )
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
