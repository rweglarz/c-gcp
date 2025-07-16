data "google_compute_network" "private" {
  name = var.private_vpc_name
}

resource "google_compute_network" "mgmt" {
  name                    = var.mgmt_vpc_name
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "mgmt" {
  name          = var.mgmt_subnet_name
  ip_cidr_range = var.mgmt_subnet_cidr
  network       = google_compute_network.mgmt.id
}

resource "google_compute_subnetwork" "private" {
  name          = var.private_subnet_name
  ip_cidr_range = var.private_subnet_cidr
  network       = data.google_compute_network.private.id
}



resource "google_compute_router" "this" {
  name    = "${var.mgmt_vpc_name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "nat" {
  name   = "${var.mgmt_vpc_name}-nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "this" {
  name   = "${var.mgmt_vpc_name}-rtr-nat"
  router = google_compute_router.this.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat.id]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
