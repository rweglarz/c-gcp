resource "google_compute_firewall" "public_ingress" {
  name          = "${var.name}-public-ingress"
  network       = google_compute_network.public.id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

# General ingress rules for internal/mgmt/remote networks
resource "google_compute_firewall" "internal_ingress" {
  for_each = merge(
    {
      mgmt    = google_compute_network.mgmt.id
      private = google_compute_network.private.id
      vpn     = google_compute_network.vpn.id
      remote  = google_compute_network.remote.id
    },
    { for k, v in google_compute_network.workload : k => v.id }
  )

  name          = "${var.name}-${each.key}-internal"
  network       = each.value
  direction     = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : r.cidr],
    [for r in var.gcp_ips : r.cidr]
  )
  allow {
    protocol = "all"
  }
}

# Allow external traffic to terminate IPsec VPN on the SDGWs in the vpn VPC
resource "google_compute_firewall" "sdgw_vpn_ingress" {
  name          = "${var.name}-sdgw-vpn-ingress"
  network       = google_compute_network.vpn.id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"] # Tunnels from remote HA VPN gateway or internet
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  allow {
    protocol = "esp"
  }
}
