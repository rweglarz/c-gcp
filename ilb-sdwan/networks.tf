#region Management Network
resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = local.cidrs.mgmt
  network       = google_compute_network.mgmt.id
}

resource "google_compute_router" "router_mgmt" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "cloud_nat_mgmt" {
  name   = "${var.name}-nat-ip-mgmt"
  region = google_compute_subnetwork.mgmt.region
}

resource "google_compute_router_nat" "router_nat_mgmt" {
  name   = "${var.name}-rtr-nat-mgmt"
  router = google_compute_router.router_mgmt.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat_mgmt.id]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
#endregion

#region Public Network
resource "google_compute_network" "public" {
  name                    = "${var.name}-public"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-public-s"
  ip_cidr_range = local.cidrs.public
  network       = google_compute_network.public.id
}

resource "google_compute_router" "router_public" {
  name    = "${var.name}-rtr-public"
  network = google_compute_network.public.id
}

resource "google_compute_router_nat" "router_public_nat" {
  name   = "${var.name}-rtr-public-nat"
  router = google_compute_router.router_public.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
#endregion

#region Private Network
resource "google_compute_network" "private" {
  name                            = "${var.name}-private"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.name}-private-s"
  ip_cidr_range = local.cidrs.private
  network       = google_compute_network.private.id
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
#endregion

#region VPN (fw-vpn) Network
resource "google_compute_network" "vpn" {
  name                            = "${var.name}-vpn"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "vpn" {
  name          = "${var.name}-vpn-s"
  ip_cidr_range = local.cidrs.vpn
  network       = google_compute_network.vpn.id
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Explicit route for direct internet gateway routing in the VPN VPC
resource "google_compute_route" "vpn_internet" {
  name             = "${var.name}-vpn-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpn.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}
#endregion

#region Remote (Branch) Network
resource "google_compute_network" "remote" {
  name                    = "${var.name}-remote"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "remote" {
  name          = "${var.name}-remote-s"
  ip_cidr_range = local.cidrs.remote
  network       = google_compute_network.remote.id
}

resource "google_compute_router" "router_remote" {
  name    = "${var.name}-rtr-remote"
  network = google_compute_network.remote.id
  bgp {
    asn               = local.asn.remote_router
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "router_remote_nat" {
  name   = "${var.name}-rtr-remote-nat"
  router = google_compute_router.router_remote.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
#endregion

#region Workload Networks
resource "google_compute_network" "workload" {
  for_each                        = toset(["workload-a", "workload-b"])
  name                            = "${var.name}-${each.key}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "workload" {
  for_each      = toset(["workload-a", "workload-b"])
  name          = "${var.name}-${each.key}-s"
  ip_cidr_range = local.cidrs[each.key]
  network       = google_compute_network.workload[each.key].id
}

# Peering workload to private VPC (firewall trust)
resource "google_compute_network_peering" "private_to_workload" {
  for_each             = google_compute_network.workload
  name                 = "${var.name}-private-to-${each.key}"
  network              = google_compute_network.private.id
  peer_network         = each.value.id
  export_custom_routes = true
}

resource "google_compute_network_peering" "workload_to_private" {
  for_each             = google_compute_network.workload
  name                 = "${var.name}-${each.key}-to-private"
  network              = each.value.id
  peer_network         = google_compute_network.private.id
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.private_to_workload
  ]
}
#endregion
