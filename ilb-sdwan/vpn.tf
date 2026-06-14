# GCP HA VPN Gateway in the Remote VPC
resource "google_compute_ha_vpn_gateway" "remote" {
  name    = "${var.name}-remote-ha-vpn"
  network = google_compute_network.remote.id
}

# External Peer VPN Gateway representing our two SDGW VMs
resource "google_compute_external_vpn_gateway" "sdgw_peers" {
  name            = "${var.name}-sdgw-peers"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = google_compute_address.sdgw_pub["sdgw1"].address
  }

  interface {
    id         = 1
    ip_address = google_compute_address.sdgw_pub["sdgw2"].address
  }
}

# Shared IPsec pre-shared key (PSK)
resource "random_id" "vpn_psk" {
  byte_length = 16
}

# -------------------------------------------------------------
# SDGW1 Tunnels (Full Mesh to both HA VPN Interfaces)
# -------------------------------------------------------------

# Tunnel 1: Remote HA VPN (interface 0) <-> SDGW1
resource "google_compute_vpn_tunnel" "remote_to_sdgw1_t1" {
  name                            = "${var.name}-tunnel-remote-to-sdgw1-t1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.remote.id
  peer_external_gateway           = google_compute_external_vpn_gateway.sdgw_peers.id
  peer_external_gateway_interface = 0
  shared_secret                   = random_id.vpn_psk.hex
  ike_version                     = 2
  vpn_gateway_interface           = 0
  router                          = google_compute_router.router_remote.name
}

resource "google_compute_router_interface" "remote_sdgw1_t1" {
  name       = "${var.name}-intf-remote-sdgw1-t1"
  router     = google_compute_router.router_remote.name
  region     = var.region
  ip_range   = "${local.tunnel_ips.sdgw1_t1.router_ip}/30"
  vpn_tunnel = google_compute_vpn_tunnel.remote_to_sdgw1_t1.name
}

resource "google_compute_router_peer" "remote_sdgw1_t1" {
  name            = "${var.name}-peer-remote-sdgw1-t1"
  router          = google_compute_router.router_remote.name
  region          = var.region
  interface       = google_compute_router_interface.remote_sdgw1_t1.name
  peer_ip_address = local.tunnel_ips.sdgw1_t1.sdgw_ip
  peer_asn        = local.asn.sdgw1
}

# Tunnel 2: Remote HA VPN (interface 1) <-> SDGW1
resource "google_compute_vpn_tunnel" "remote_to_sdgw1_t2" {
  name                            = "${var.name}-tunnel-remote-to-sdgw1-t2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.remote.id
  peer_external_gateway           = google_compute_external_vpn_gateway.sdgw_peers.id
  peer_external_gateway_interface = 0
  shared_secret                   = random_id.vpn_psk.hex
  ike_version                     = 2
  vpn_gateway_interface           = 1
  router                          = google_compute_router.router_remote.name
}

resource "google_compute_router_interface" "remote_sdgw1_t2" {
  name       = "${var.name}-intf-remote-sdgw1-t2"
  router     = google_compute_router.router_remote.name
  region     = var.region
  ip_range   = "${local.tunnel_ips.sdgw1_t2.router_ip}/30"
  vpn_tunnel = google_compute_vpn_tunnel.remote_to_sdgw1_t2.name
}

resource "google_compute_router_peer" "remote_sdgw1_t2" {
  name            = "${var.name}-peer-remote-sdgw1-t2"
  router          = google_compute_router.router_remote.name
  region          = var.region
  interface       = google_compute_router_interface.remote_sdgw1_t2.name
  peer_ip_address = local.tunnel_ips.sdgw1_t2.sdgw_ip
  peer_asn        = local.asn.sdgw1
}

# -------------------------------------------------------------
# SDGW2 Tunnels (Full Mesh to both HA VPN Interfaces)
# -------------------------------------------------------------

# Tunnel 1: Remote HA VPN (interface 0) <-> SDGW2
resource "google_compute_vpn_tunnel" "remote_to_sdgw2_t1" {
  name                            = "${var.name}-tunnel-remote-to-sdgw2-t1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.remote.id
  peer_external_gateway           = google_compute_external_vpn_gateway.sdgw_peers.id
  peer_external_gateway_interface = 1
  shared_secret                   = random_id.vpn_psk.hex
  ike_version                     = 2
  vpn_gateway_interface           = 0
  router                          = google_compute_router.router_remote.name
}

resource "google_compute_router_interface" "remote_sdgw2_t1" {
  name       = "${var.name}-intf-remote-sdgw2-t1"
  router     = google_compute_router.router_remote.name
  region     = var.region
  ip_range   = "${local.tunnel_ips.sdgw2_t1.router_ip}/30"
  vpn_tunnel = google_compute_vpn_tunnel.remote_to_sdgw2_t1.name
}

resource "google_compute_router_peer" "remote_sdgw2_t1" {
  name            = "${var.name}-peer-remote-sdgw2-t1"
  router          = google_compute_router.router_remote.name
  region          = var.region
  interface       = google_compute_router_interface.remote_sdgw2_t1.name
  peer_ip_address = local.tunnel_ips.sdgw2_t1.sdgw_ip
  peer_asn        = local.asn.sdgw2
}

# Tunnel 2: Remote HA VPN (interface 1) <-> SDGW2
resource "google_compute_vpn_tunnel" "remote_to_sdgw2_t2" {
  name                            = "${var.name}-tunnel-remote-to-sdgw2-t2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.remote.id
  peer_external_gateway           = google_compute_external_vpn_gateway.sdgw_peers.id
  peer_external_gateway_interface = 1
  shared_secret                   = random_id.vpn_psk.hex
  ike_version                     = 2
  vpn_gateway_interface           = 1
  router                          = google_compute_router.router_remote.name
}

resource "google_compute_router_interface" "remote_sdgw2_t2" {
  name       = "${var.name}-intf-remote-sdgw2-t2"
  router     = google_compute_router.router_remote.name
  region     = var.region
  ip_range   = "${local.tunnel_ips.sdgw2_t2.router_ip}/30"
  vpn_tunnel = google_compute_vpn_tunnel.remote_to_sdgw2_t2.name
}

resource "google_compute_router_peer" "remote_sdgw2_t2" {
  name            = "${var.name}-peer-remote-sdgw2-t2"
  router          = google_compute_router.router_remote.name
  region          = var.region
  interface       = google_compute_router_interface.remote_sdgw2_t2.name
  peer_ip_address = local.tunnel_ips.sdgw2_t2.sdgw_ip
  peer_asn        = local.asn.sdgw2
}
