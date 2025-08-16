resource "google_compute_firewall" "public-i" {
  name      = "${var.name}-public-i"
  network   = google_compute_network.public.id
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "this-i" {
  for_each = merge(
    {
      mgmt     = google_compute_network.mgmt.id
    },
    { for k,v in google_compute_network.private: "private-${k}" => v.id },
    { for k,v in google_compute_network.peer: "peer-${k}" => v.id },
    { for k,v in google_compute_network.vpnpeer: "vpn-peer-${k}" => v.id },
    { for k,v in google_compute_network.nccpeer: "ncc-peer-${k}" => v.id },
  )
  name      = "${var.name}-${each.key}-i"
  network   = each.value
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : r.cidr],
    [for r in var.gcp_ips  : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
