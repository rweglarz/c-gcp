resource "random_bytes" "psk" {
  length = 12
}

resource google_compute_ha_vpn_gateway "a" {
  name    = "${var.name}-${var.vpc_a_name}"
  network = var.vpc_a_id
  region  = var.region
}


resource google_compute_ha_vpn_gateway "b" {
  name    = "${var.name}-${var.vpc_b_name}"
  network = var.vpc_b_id
  region  = var.region
}


resource "google_compute_router" "a" {
  name    = "${var.name}-${var.vpc_a_name}"
  network = var.vpc_a_id
  region  = var.region
  bgp {
    asn =  var.vpc_a_asn
    advertise_mode = length(var.advertised_ip_ranges_a)==0 ? "DEFAULT" : "CUSTOM"
    dynamic "advertised_ip_ranges" {
      for_each = var.advertised_ip_ranges_a
      content {
        range = advertised_ip_ranges.value
      } 
    }
  }
}

resource "google_compute_router" "b" {
  name    = "${var.name}-${var.vpc_b_name}"
  network = var.vpc_b_id
  region  = var.region
  bgp {
    asn =  var.vpc_b_asn
    advertise_mode = length(var.advertised_ip_ranges_b)==0 ? "DEFAULT" : "CUSTOM"
    dynamic "advertised_ip_ranges" {
      for_each = var.advertised_ip_ranges_b
      content {
        range = advertised_ip_ranges.value
      } 
    }
  }
}


resource "google_compute_vpn_tunnel" "a_b" {
  count = 2
  name                  = "${var.name}-a-b-${count.index}"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.a.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.b.id
  shared_secret         = random_bytes.psk.hex
  router                = google_compute_router.a.id
  vpn_gateway_interface = count.index
}

resource "google_compute_vpn_tunnel" "b_a" {
  count = 2
  name                  = "${var.name}-b-a-${count.index}"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.b.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.a.id
  shared_secret         = random_bytes.psk.hex
  router                = google_compute_router.b.id
  vpn_gateway_interface = count.index
}

resource "google_compute_router_interface" "a" {
  count = 2
  name       = "interface-${count.index}"
  router     = google_compute_router.a.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.a_b[count.index].name
  ip_range   = "${cidrhost(var.peering_cidrs[count.index], 1)}/30"
}

resource "google_compute_router_interface" "b" {
  count = 2
  name       = "interface-${count.index}"
  router     = google_compute_router.b.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.b_a[count.index].name
  ip_range   = "${cidrhost(var.peering_cidrs[count.index], 2)}/30"
}


resource "google_compute_router_peer" "a" {
  count = 2
  name       = "to-${var.vpc_b_name}-${count.index}"
  router     = google_compute_router.a.name
  region     = var.region
  peer_asn   = var.vpc_b_asn
  interface  = google_compute_router_interface.a[count.index].name
  peer_ip_address = cidrhost(var.peering_cidrs[count.index], 2)
}

resource "google_compute_router_peer" "b" {
  count = 2
  name       = "to-${var.vpc_a_name}-${count.index}"
  router     = google_compute_router.b.name
  region     = var.region
  peer_asn   = var.vpc_a_asn
  interface  = google_compute_router_interface.b[count.index].name
  peer_ip_address = cidrhost(var.peering_cidrs[count.index], 1)
}
