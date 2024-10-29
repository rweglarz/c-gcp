resource "google_compute_firewall" "pan" {
  name      = "lab-${var.name}-pan-i"
  project   = var.project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    [for k,v in google_compute_instance.fwp: v.network_interface.1.access_config.0.nat_ip],
    [for k,v in google_compute_instance.fws: v.network_interface.1.access_config.0.nat_ip],
  )
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
