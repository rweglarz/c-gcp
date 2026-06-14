resource "google_network_connectivity_hub" "vpn_hub" {
  name        = "${var.name}-vpn-hub"
  description = "Hub for the SD-WAN/VPN VPC"
}

resource "google_compute_router" "router_vpn" {
  name    = "${var.name}-rtr-vpn"
  network = google_compute_network.vpn.id
  bgp {
    asn               = local.asn.vpn_router
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    advertised_ip_ranges {
      range       = cidrsubnet(var.cidr, 1, 0)
      description = "lower half, summary-supernet"
    }
    advertised_ip_ranges {
      range       = local.cidrs["workload-a"]
      description = "Workload A "
    }
    advertised_ip_ranges {
      range       = local.cidrs["workload-b"]
      description = "Workload B"
    }
  }
}

resource "google_compute_router_interface" "vpn_primary" {
  name                = "${var.name}-intf-vpn-primary"
  region              = var.region
  router              = google_compute_router.router_vpn.name
  subnetwork          = google_compute_subnetwork.vpn.self_link
  private_ip_address  = local.vpn_router_ips.primary
  redundant_interface = google_compute_router_interface.vpn_redundant.name
}

resource "google_compute_router_interface" "vpn_redundant" {
  name               = "${var.name}-intf-vpn-red"
  region             = var.region
  router             = google_compute_router.router_vpn.name
  subnetwork         = google_compute_subnetwork.vpn.self_link
  private_ip_address = local.vpn_router_ips.redundant
}
