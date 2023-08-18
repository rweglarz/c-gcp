resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  region  = "us-central1"
  name    = "ha-vpn-1"
  network = google_compute_network.network1.id
}

resource "google_compute_ha_vpn_gateway" "ha_gateway2" {
  region  = "us-central1"
  name    = "ha-vpn-2"
  network = google_compute_network.network2.id
}

resource "google_compute_ha_vpn_gateway" "ha_gateway3" {
  region  = "us-central1"
  name    = "ha-vpn-3"
  network = google_compute_network.network3.id
}



resource "google_compute_network" "network1" {
  name                    = "network1"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_network" "network2" {
  name                    = "network2"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_network" "network3" {
  name                    = "network3"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "network1_subnet1" {
  name          = "ha-vpn-subnet-1-1"
  ip_cidr_range = "10.0.1.0/25"
  region        = "us-central1"
  network       = google_compute_network.network1.id
}

resource "google_compute_subnetwork" "network1_subnet2" {
  name          = "ha-vpn-subnet-1-2"
  ip_cidr_range = "10.0.1.128/25"
  region        = "us-west1"
  network       = google_compute_network.network1.id
}

resource "google_compute_subnetwork" "network2_subnet1" {
  name          = "ha-vpn-subnet-2-1"
  ip_cidr_range = "10.0.2.0/25"
  region        = "us-central1"
  network       = google_compute_network.network2.id
}

resource "google_compute_subnetwork" "network2_subnet2" {
  name          = "ha-vpn-subnet-2-2"
  ip_cidr_range = "10.0.2.128/25"
  region        = "us-east1"
  network       = google_compute_network.network2.id
}

resource "google_compute_subnetwork" "network3_subnet1" {
  name          = "ha-vpn-subnet-3-1"
  ip_cidr_range = "10.0.3.0/25"
  region        = "us-central1"
  network       = google_compute_network.network3.id
}

resource "google_compute_subnetwork" "network3_subnet2" {
  name          = "ha-vpn-subnet-3-2"
  ip_cidr_range = "10.0.3.128/25"
  region        = "us-east1"
  network       = google_compute_network.network3.id
}


resource "google_compute_router" "router1" {
  name    = "ha-vpn-router1"
  network = google_compute_network.network1.name
  bgp {
    asn            = 64521
    advertise_mode = "CUSTOM"
    advertised_groups = [
      "ALL_SUBNETS",
    ]
    advertised_ip_ranges {
      range = "10.0.1.0/24"
    }
  }
}

resource "google_compute_router" "router2" {
  name    = "ha-vpn-router2"
  network = google_compute_network.network2.name
  bgp {
    asn = 64522

    advertise_mode = "CUSTOM"

    advertised_ip_ranges {
      range = "10.0.0.0/16"
    }
  }
}

resource "google_compute_router" "router3" {
  name    = "ha-vpn-router3"
  network = google_compute_network.network3.name
  bgp {
    asn = 64523

    advertise_mode = "CUSTOM"

    advertised_ip_ranges {
      range = "10.0.3.0/24"
    }
  }
}



resource "google_compute_vpn_tunnel" "tunnel12_i0" {
  name                  = "ha-vpn-tunnel-12-i0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel12_i1" {
  name                  = "ha-vpn-tunnel-12-i1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel21_i0" {
  name                  = "ha-vpn-tunnel-21-i0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel21_i1" {
  name                  = "ha-vpn-tunnel-21-i1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel23_i0" {
  name                  = "ha-vpn-tunnel-23-i0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway3.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel23_i1" {
  name                  = "ha-vpn-tunnel-23-i1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway3.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel32_i0" {
  name                  = "ha-vpn-tunnel-32-i0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway3.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router3.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel32_i1" {
  name                  = "ha-vpn-tunnel-32-i1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway3.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router3.id
  vpn_gateway_interface = 1
}



resource "google_compute_router_interface" "router1_i0" {
  name       = "router1-interface1"
  router     = google_compute_router.router1.name
  region     = "us-central1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel12_i0.name
}

resource "google_compute_router_peer" "router1_peer2_i0" {
  name                      = "router1-peer2-i0"
  router                    = google_compute_router.router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64522
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_i0.name
}

resource "google_compute_router_interface" "router1_i1" {
  name       = "router1-i1"
  router     = google_compute_router.router1.name
  region     = "us-central1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel12_i1.name
}

resource "google_compute_router_peer" "router1_router2_i1" {
  name                      = "router1-router2-i0"
  router                    = google_compute_router.router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64522
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_i1.name
}

resource "google_compute_router_interface" "router2_i0" {
  name       = "router2-i0"
  router     = google_compute_router.router2.name
  region     = "us-central1"
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel21_i0.name
}

resource "google_compute_router_peer" "router2_router1_i0" {
  name                      = "router2-router1-i0"
  router                    = google_compute_router.router2.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64521
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_i0.name
}

resource "google_compute_router_interface" "router2_i1" {
  name       = "router2-i1"
  router     = google_compute_router.router2.name
  region     = "us-central1"
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel21_i1.name
}

resource "google_compute_router_peer" "router2_router1_i1" {
  name                      = "router2-router1-i1"
  router                    = google_compute_router.router2.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64521
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_i1.name
}









resource "google_compute_router_interface" "router2_i3" {
  name       = "router2-i3"
  router     = google_compute_router.router2.name
  region     = "us-central1"
  ip_range   = "169.254.23.2/29"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel23_i0.name
}

resource "google_compute_router_peer" "router2_router3_i0" {
  name                      = "router2-router3-i0"
  router                    = google_compute_router.router2.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.23.3"
  peer_asn                  = 64523
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_i3.name
}


resource "google_compute_router_interface" "router3_i0" {
  name       = "router3-i0"
  router     = google_compute_router.router3.name
  region     = "us-central1"
  ip_range   = "169.254.23.3/29"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel32_i0.name
}

resource "google_compute_router_peer" "router3_router2_i0" {
  name                      = "router3-router2-i0"
  router                    = google_compute_router.router3.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.23.2"
  peer_asn                  = 64522
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router3_i0.name
}
