resource "google_compute_firewall" "pan" {
  name      = "lab-gcp-${var.name}-pan-i"
  project   = var.project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    [
      google_compute_address.fw_mgmt[0].address,
      google_compute_address.fw_mgmt[1].address,
    ]
  )
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
