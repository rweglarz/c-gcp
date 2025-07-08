resource "google_compute_network" "this" {
  for_each = local.subnets

  name                    = "${var.name}-${each.key}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "this" {
  for_each = local.subnets

  name          = "${var.name}-${each.key}"
  ip_cidr_range = cidrsubnet(var.cidr, 4, each.value.idx)
  network       = google_compute_network.this[each.key].id
}


resource "google_compute_firewall" "this-i" {
  for_each = google_compute_network.this

  name      = "${var.name}-${each.key}-i"
  network   = each.value.id
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}



resource "google_compute_router" "this" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.this["mgmt"].id
}

resource "google_compute_address" "nat" {
  name   = "${var.name}-nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "this" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.this.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat.id]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}