resource google_compute_ha_vpn_gateway "private" {
  for_each = local.cidrs.private

  region  = var.region
  name    = "${var.name}-${each.key}"
  network = google_compute_network.private[each.key].id
}


resource google_compute_network "vpnpeer" {
  for_each = local.cidrs_v_m
  name                    = "${var.name}-${each.key}"
  auto_create_subnetworks = "false"
  delete_default_routes_on_create = true
}

resource google_compute_subnetwork "vpnpeer" {
  for_each = google_compute_network.vpnpeer
  name          = "${var.name}-${each.key}-s"
  ip_cidr_range = local.cidrs_v_m[each.key].cidr
  network       = each.value.id
}


resource google_compute_ha_vpn_gateway "vpnpeer" {
  for_each = google_compute_network.vpnpeer
  region  = var.region
  name    = "${var.name}-vp-${each.key}"
  network  = each.value.id
}

resource "random_id" "psk" {
  byte_length = 8
}


resource "google_compute_router" "private" {
  for_each = google_compute_network.private
  name    = "${var.name}-${each.key}"
  network = each.value.id
  bgp {
    asn            = local.asn[each.key]
    advertise_mode = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "172.16.0.0/12"
    }
  }
}

resource "google_compute_router" "vpnpeer" {
  for_each = google_compute_network.vpnpeer
  name    = "${var.name}-${each.key}"
  network       = google_compute_network.vpnpeer[each.key].id
  bgp {
    asn            = local.asn[each.key]
    advertise_mode = "DEFAULT"
  }
}


resource "google_compute_vpn_tunnel" "private_fw" {
  for_each = google_compute_network.vpnpeer
  name                  = "${var.name}-${each.key}-fw"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.private[local.cidrs_v_m[each.key].lk].id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpnpeer[each.key].id
  shared_secret         = random_id.psk.hex
  router                = google_compute_router.private[local.cidrs_v_m[each.key].lk].id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "private_peer" {
  for_each = google_compute_network.vpnpeer
  name                  = "${var.name}-${each.key}-peer"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.vpnpeer[each.key].id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.private[local.cidrs_v_m[each.key].lk].id
  shared_secret         = random_id.psk.hex
  router                = google_compute_router.vpnpeer[each.key].id
  vpn_gateway_interface = 0
}




resource "google_compute_router_interface" "private_fw" {
  for_each   = google_compute_vpn_tunnel.private_fw
  name       = "${var.name}-${each.key}-fw"
  router     = google_compute_router.private[local.cidrs_v_m[each.key].lk].name
  region     = var.region
  vpn_tunnel = each.value.name
  ip_range   = "${cidrhost(local.peering_cidrs[each.key], 0)}/31"
}

resource "google_compute_router_interface" "private_peer" {
  for_each   = google_compute_vpn_tunnel.private_peer
  name       = "${var.name}-${each.key}-peer"
  router     = google_compute_router.vpnpeer[each.key].name
  region     = var.region
  vpn_tunnel = each.value.name
  ip_range   = "${cidrhost(local.peering_cidrs[each.key], 1)}/31"
}

resource "google_compute_router_peer" "private_fw" {
  for_each   = google_compute_vpn_tunnel.private_fw
  name       = "${var.name}-${each.key}-fw"
  router     = google_compute_router.private[local.cidrs_v_m[each.key].lk].name
  region     = var.region
  peer_asn   = local.asn[each.key]
  interface  = google_compute_router_interface.private_fw[each.key].name
  peer_ip_address = cidrhost(local.peering_cidrs[each.key], 1)
}

resource "google_compute_router_peer" "private_peer" {
  for_each   = google_compute_vpn_tunnel.private_peer
  name       = "${var.name}-${each.key}-peer"
  router     = google_compute_router.vpnpeer[each.key].name
  region     = var.region
  peer_asn   = local.asn[local.cidrs_v_m[each.key].lk]
  interface  = google_compute_router_interface.private_peer[each.key].name
  peer_ip_address = cidrhost(local.peering_cidrs[each.key], 0)
}
