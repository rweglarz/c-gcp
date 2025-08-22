resource "google_compute_network" "spoke" {
  for_each = local.spokes

  name                    = "${var.name}-spoke-${each.key}"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "spoke" {
  for_each      = local.spoke_subnets

  name          = "${var.name}-${each.key}"
  region        = each.value.subnet_name=="s1" ? local.regions[0] : local.regions[1]
  ip_cidr_range = each.value.cidr
  network       = google_compute_network.spoke[each.value.spoke_name].self_link
}

resource "google_compute_network" "center" {
  name                    = "${var.name}-center"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "center" {
  for_each      = local.centers

  name          = "${var.name}-${each.key}"
  region        = each.key=="s1" ? local.regions[0] : local.regions[1]
  ip_cidr_range = each.value
  network       = google_compute_network.center.self_link
}



resource "google_network_connectivity_spoke" "center" {
  name     = "${var.name}-center"
  hub      = google_network_connectivity_hub.this.id
  group    = google_network_connectivity_group.center.id
  location = "global"
  linked_vpc_network {
    uri = google_compute_network.center.self_link
  }
}

resource "google_network_connectivity_spoke" "center_vpn" {
  for_each = toset(local.regions)

  name     = "${var.name}-center-vpn"
  hub      = google_network_connectivity_hub.this.id
  group    = google_network_connectivity_group.center.id
  location = each.key
  linked_vpn_tunnels {
    uris = module.vpns[each.key].tunnels["ncc--to--fw"]

    include_import_ranges      = ["ALL_IPV4_RANGES"]
    site_to_site_data_transfer = true
  }
}

resource "google_network_connectivity_spoke" "spoke" {
  for_each = google_compute_network.spoke

  name     = "${var.name}-${each.key}"
  hub      = google_network_connectivity_hub.this.id
  group    = google_network_connectivity_group.edge.id
  location = "global"
  linked_vpc_network {
    uri = each.value.self_link
  }
}
