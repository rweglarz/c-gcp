resource "google_compute_network_peering" "gke_airs" {
  count = var.airs_vpc_id!=null ? 1 : 0

  name                 = "${var.name}-gke-airs"
  network              = google_compute_network.gke.id
  peer_network         = var.airs_vpc_id
  export_custom_routes = true
}

resource "google_compute_network_peering" "airs_gke" {
  count = var.airs_vpc_id!=null ? 1 : 0

  name                 = "${var.name}-airs-gke"
  network              = var.airs_vpc_id
  peer_network         = google_compute_network.gke.id
  import_custom_routes = false

  depends_on = [
    google_compute_network_peering.gke_airs
  ]
}
