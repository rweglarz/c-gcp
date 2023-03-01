resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 0)
  network       = google_compute_network.mgmt.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

resource "google_compute_network" "internet" {
  name                    = "${var.name}-internet"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "internet" {
  name          = "${var.name}-internet-s"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 1)
  network       = google_compute_network.internet.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

resource "google_compute_network" "internal" {
  name                    = "${var.name}-internal"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "internal" {
  name          = "${var.name}-internal-s"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 2)
  network       = google_compute_network.internal.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}
resource "google_compute_network" "ha" {
  name                    = "${var.name}-ha"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "ha" {
  name          = "${var.name}-ha-s"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 3)
  network       = google_compute_network.ha.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

resource "google_compute_network" "srv0" {
  name                    = "${var.name}-srv0"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "srv0-s0" {
  name          = "${var.name}-srv0-s0"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 4)
  network       = google_compute_network.srv0.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}
resource "google_compute_network" "srv1" {
  name                    = "${var.name}-srv1"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "srv1-s0" {
  name          = "${var.name}-srv1-s0"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 5)
  network       = google_compute_network.srv1.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}







resource "google_compute_firewall" "mgmt-i" {
  name      = "${var.name}-mgmt-i"
  network   = google_compute_network.mgmt.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "internet-i" {
  name      = "${var.name}-internet-i"
  network   = google_compute_network.internet.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for r in var.gcp_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "internal-i" {
  name      = "${var.name}-internal-i"
  network   = google_compute_network.internal.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.gcp_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "srv0-i" {
  name      = "${var.name}-srv0-i"
  network   = google_compute_network.srv0.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for r in var.gcp_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "srv1-i" {
  name      = "${var.name}-srv1-i"
  network   = google_compute_network.srv1.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for r in var.gcp_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "mgmt-i-tmp" {
  name      = "${var.name}-mgmt-i-tmp"
  network   = google_compute_network.mgmt.id
  direction = "INGRESS"
  source_ranges = concat(
    [for r in var.tmp_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_route" "srv0-dg" {
  name         = "${var.name}-srv0-dg"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.srv0.id
  next_hop_ilb = google_compute_forwarding_rule.internal.ip_address
  priority     = 10
}
resource "google_compute_route" "srv1-dg" {
  name         = "${var.name}-srv1-dg"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.srv1.id
  next_hop_ilb = google_compute_forwarding_rule.internal.ip_address
  priority     = 10
}


resource "google_compute_route" "srv0-mgmt-exc" {
  for_each         = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr }
  name             = "${var.name}-srv0-${each.key}"
  description      = "srv0 traffic exceptions"
  dest_range       = each.value
  network          = google_compute_network.srv0.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
}

resource "google_compute_route" "srv1-mgmt-exc" {
  for_each         = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr }
  name             = "${var.name}-srv1-${each.key}"
  description      = "srv1 traffic exceptions"
  dest_range       = each.value
  network          = google_compute_network.srv1.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
}


resource "google_compute_network_peering" "internal-srv0" {
  name         = "${var.name}-internal-srv0"
  network      = google_compute_network.internal.self_link
  peer_network = google_compute_network.srv0.self_link
}
resource "google_compute_network_peering" "srv0-internal" {
  name         = "${var.name}-srv0-internal"
  network      = google_compute_network.srv0.self_link
  peer_network = google_compute_network.internal.self_link
  depends_on = [
    google_compute_network_peering.internal-srv0
  ]
}
resource "google_compute_network_peering" "internal-srv1" {
  name         = "${var.name}-internal-srv1"
  network      = google_compute_network.internal.self_link
  peer_network = google_compute_network.srv1.self_link
  depends_on = [
    google_compute_network_peering.srv0-internal
  ]
}
resource "google_compute_network_peering" "srv1-internal" {
  name         = "${var.name}-srv1-internal"
  network      = google_compute_network.srv1.self_link
  peer_network = google_compute_network.internal.self_link
  depends_on = [
    google_compute_network_peering.internal-srv1
  ]
}
