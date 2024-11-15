resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = local.cidrs.mgmt
  network       = google_compute_network.mgmt.id
}

resource "google_compute_network" "public" {
  name                    = "${var.name}-public"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-public-s"
  ip_cidr_range = local.cidrs.public
  network       = google_compute_network.public.id
}

resource "google_compute_network" "private" {
  for_each = local.cidrs.private

  name                    = "${var.name}-private-${each.key}"
  auto_create_subnetworks = "false"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "private" {
  for_each = local.cidrs.private
  name          = "${var.name}-private-${each.key}-s"
  ip_cidr_range = local.cidrs.private[each.key]
  network       = google_compute_network.private[each.key].id
}

resource "google_compute_network" "peer" {
  for_each = { for v in local.cidrs_p_f: v.n => v }
  name                    = "${var.name}-${each.key}"
  auto_create_subnetworks = "false"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "peer" {
  for_each = { for v in local.cidrs_p_f: v.n => v }
  name          = "${var.name}-${each.key}-s"
  ip_cidr_range = each.value.cidr
  network       = google_compute_network.peer[each.key].id
}


resource "google_compute_router" "router" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "cloud_nat" {
  name   = "${var.name}-nat-ip"
  region = google_compute_subnetwork.mgmt.region
}

resource "google_compute_router_nat" "router_nat" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat.id]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_router" "router_public" {
  name    = "${var.name}-rtr-public"
  network = google_compute_network.public.id
}

resource "google_compute_router_nat" "router_public_nat" {
  name   = "${var.name}-rtr-public-nat"
  router = google_compute_router.router_public.name

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_network_peering" "private_fw" {
  for_each = google_compute_network.peer
  name                 = "${var.name}-${each.key}-fw"
  network              = google_compute_network.private[local.cidrs_p_m[each.key].lk].id
  peer_network         = each.value.id
  export_custom_routes = true
}

resource "google_compute_network_peering" "private_peer" {
  for_each = google_compute_network.peer
  name                 = "${var.name}-${each.key}-peer"
  network              = each.value.id
  peer_network         = google_compute_network.private[local.cidrs_p_m[each.key].lk].id
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.private_fw
  ]
}

