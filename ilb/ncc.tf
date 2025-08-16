resource "google_network_connectivity_hub" "private" {
  for_each = var.deploy_ncc ? google_compute_network.private : {}

  name = "${var.name}-private-${each.key}"

  preset_topology = "MESH"
}

resource "google_network_connectivity_spoke" "private"  {
  for_each = var.deploy_ncc ? google_compute_network.private : {}

  name = each.key
  location = "global"
  hub = google_network_connectivity_hub.private[each.key].id
  linked_vpc_network {
    uri = each.value.self_link
  }
}

resource "google_compute_network" "nccpeer" {
  for_each = var.deploy_ncc ? local.cidrs_ncc_m : {}

  name                    = "${var.name}-${each.key}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "nccpeer" {
  for_each = var.deploy_ncc ? local.cidrs_ncc_m : {}

  name          = "${var.name}-${each.key}-s"
  ip_cidr_range = each.value.cidr
  network       = google_compute_network.nccpeer[each.key].id
}

resource "google_network_connectivity_spoke" "nccpeer" {
  for_each = var.deploy_ncc ? local.cidrs_ncc_m : {}

  name     = each.key
  hub      = google_network_connectivity_hub.private[each.value.lk].id
  location = "global"
  linked_vpc_network {
    uri = google_compute_network.nccpeer[each.key].id
  }
}

resource "google_compute_route" "nccpeer_172" {
  for_each = var.deploy_ncc ? local.cidrs_ncc_m : {}

  name          = "${var.name}-${each.key}"
  dest_range   = "172.16.0.0/12"
  network      = google_compute_network.nccpeer[each.key].id
  next_hop_ilb = google_compute_forwarding_rule.private[each.value.lk].ip_address
  priority     = 10
}
