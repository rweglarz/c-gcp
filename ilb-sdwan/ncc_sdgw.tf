resource "google_network_connectivity_spoke" "sdgw_spoke" {
  name     = "${var.name}-sdgw-spoke"
  location = var.region
  hub      = google_network_connectivity_hub.vpn_hub.id

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.sdgw["sdgw1"].self_link
      ip_address      = local.sdgw_ips.sdgw1
    }
    instances {
      virtual_machine = google_compute_instance.sdgw["sdgw2"].self_link
      ip_address      = local.sdgw_ips.sdgw2
    }
    site_to_site_data_transfer = true
  }
}

resource "google_compute_router_peer" "vpn_sdgw1" {
  name                      = "${var.name}-peer-vpn-sdgw1"
  router                    = google_compute_router.router_vpn.name
  region                    = var.region
  interface                 = google_compute_router_interface.vpn_primary.name
  peer_asn                  = local.asn.sdgw1
  peer_ip_address           = local.sdgw_ips.sdgw1
  router_appliance_instance = google_compute_instance.sdgw["sdgw1"].self_link
  depends_on = [ 
    google_network_connectivity_spoke.sdgw_spoke
  ]
}

resource "google_compute_router_peer" "vpn_sdgw2" {
  name                      = "${var.name}-peer-vpn-sdgw2"
  router                    = google_compute_router.router_vpn.name
  region                    = var.region
  interface                 = google_compute_router_interface.vpn_redundant.name
  peer_asn                  = local.asn.sdgw2
  peer_ip_address           = local.sdgw_ips.sdgw2
  router_appliance_instance = google_compute_instance.sdgw["sdgw2"].self_link
  depends_on = [ 
    google_network_connectivity_spoke.sdgw_spoke
  ]
}
