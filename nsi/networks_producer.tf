resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = local.cidrs.mgmt
  network       = google_compute_network.mgmt.id
}


resource "google_compute_network" "private" {
  name                            = "${var.name}-private"
  auto_create_subnetworks         = "false"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.name}-private-s"
  ip_cidr_range = local.cidrs.private
  network       = google_compute_network.private.id
}


resource "google_compute_router" "mgmt" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "cloud_nat" {
  name   = "${var.name}-nat-ip"
  region = google_compute_subnetwork.mgmt.region
}

resource "google_compute_router_nat" "router_nat" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.mgmt.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat.id]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_firewall" "producer-i" {
  for_each = merge(
    {
      mgmt    = google_compute_network.mgmt.id
      private = google_compute_network.private.id
    },
  )
  name      = "${var.name}-${each.key}-i"
  network   = each.value
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "35.235.240.0/20", # iap
      "35.191.0.0/16",   # nlb hc
      "209.85.152.0/22", # nlb hc
      "209.85.204.0/22", # nlb hc
    ],
    [for r in var.mgmt_ips : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
