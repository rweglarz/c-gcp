resource "google_compute_router" "transit" {
  name     = "${var.name}-rtr-transit"
  network  = google_compute_network.transit.name
  bgp {
    asn               = 65511
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = google_compute_subnetwork.c1-nodes.ip_cidr_range
    }
    advertised_ip_ranges {
      range = google_compute_subnetwork.c1-cp.ip_cidr_range
    }
  }
}


resource "google_compute_ha_vpn_gateway" "transit" {
  name    = "transit"
  region  = var.region
  network = google_compute_network.transit.id
}


resource "google_compute_external_vpn_gateway" "azure" {
  name            = "azure"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.azure_vpn_ips[0]
  }

  interface {
    id         = 1
    ip_address = var.azure_vpn_ips[1]
  }
}


resource "google_compute_vpn_tunnel" "azure" {
  count = 2

  name          = "azure-i-${count.index}"
  region        = var.region
  shared_secret = var.vpn_psk

  router                = google_compute_router.transit.id
  vpn_gateway           = google_compute_ha_vpn_gateway.transit.id
  vpn_gateway_interface = count.index

  peer_external_gateway           = google_compute_external_vpn_gateway.azure.self_link
  peer_external_gateway_interface = count.index
}

locals {
  azure_internal_ips = [
    "169.254.21.1",
    "169.254.21.5",
  ]
  gcp_internal_ips = [
    "169.254.21.2",
    "169.254.21.6",
  ]
}

resource "google_compute_router_interface" "azure" {
  count = 2

  name       = "interface-${count.index}"
  router     = google_compute_router.transit.name
  ip_range   = "${local.gcp_internal_ips[count.index]}/30"
  vpn_tunnel = google_compute_vpn_tunnel.azure[count.index].name
}

resource "google_compute_router_peer" "azure" {
  count = 2

  name                      = "azure-${count.index}"
  router                    = google_compute_router.transit.name
  peer_ip_address           = local.azure_internal_ips[count.index]
  peer_asn                  = "65515"
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.azure[count.index].name
}

output "gcp_vpn_ips" {
  value = [
    google_compute_ha_vpn_gateway.transit.vpn_interfaces[0].ip_address,
    google_compute_ha_vpn_gateway.transit.vpn_interfaces[1].ip_address,
  ]
}
