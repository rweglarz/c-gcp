resource "google_compute_network" "transit" {
  name                    = "${var.name}-transit"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "okd" {
  name                    = "${var.name}-okd"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "c1-cp" {
  name          = "${var.name}-c1-cp"
  region        = var.region
  ip_cidr_range = cidrsubnet(var.cidr, 5, 2)
  network       = google_compute_network.okd.id
}

resource "google_compute_subnetwork" "c1-nodes" {
  name          = "${var.name}-c1-nodes"
  region        = var.region
  ip_cidr_range = cidrsubnet(var.cidr, 5, 3)
  network       = google_compute_network.okd.id
}



resource "google_compute_firewall" "okd-mgmt" {
  name      = "${var.name}-okd-mgmt"
  network   = google_compute_network.okd.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "okd-iap" {
  name      = "${var.name}-okd-iap"
  network   = google_compute_network.okd.id
  direction = "INGRESS"
  source_ranges = concat(
    ["35.235.240.0/20"],
  )
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_firewall" "okd-aks" {
  name      = "${var.name}-okd-aks"
  network   = google_compute_network.okd.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.29.0.0/20"],
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_network_peering" "transit-okd" {
  name                 = "${var.name}-transit-okd"
  network              = google_compute_network.transit.self_link
  peer_network         = google_compute_network.okd.self_link
  export_custom_routes = true
}

resource "google_compute_network_peering" "okd-transit" {
  name                 = "${var.name}-okd-transit"
  network              = google_compute_network.okd.self_link
  peer_network         = google_compute_network.transit.self_link
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.transit-okd
  ]
}


resource "google_compute_address" "okd" {
  name   = "${var.name}-rtr-okd"
  region = var.region
}

resource "google_compute_router" "okd" {
  name     = "${var.name}-rtr-okd"
  network  = google_compute_network.okd.name

}

resource "google_compute_router_nat" "okd" {
  name     = "${var.name}-okd-snat"
  router   = google_compute_router.okd.name
  region   = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [
    google_compute_address.okd.self_link
  ]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
