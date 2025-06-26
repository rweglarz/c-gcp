resource "google_compute_network_peering" "okd_airs" {
  count = var.airs_vpc_id!=null ? 1 : 0

  name                 = "${var.name}-okd-airs"
  network              = google_compute_network.okd.id
  peer_network         = var.airs_vpc_id
  # export_custom_routes = true
}

resource "google_compute_network_peering" "airs_okd" {
  count = var.airs_vpc_id!=null ? 1 : 0

  name                 = "${var.name}-airs-okd"
  network              = var.airs_vpc_id
  peer_network         = google_compute_network.okd.id
  # import_custom_routes = false

  depends_on = [
    google_compute_network_peering.okd_airs
  ]
}
