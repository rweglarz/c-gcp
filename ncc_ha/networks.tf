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

resource "google_compute_network" "other" {
  name                    = "${var.name}-other"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "other" {
  count         = 4
  name          = "${var.name}-other-s${count.index}"
  ip_cidr_range = cidrsubnet(var.cidr, 4, 4 + count.index)
  network       = google_compute_network.other.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}





resource "google_compute_firewall" "mgmt-i" {
  name      = "${var.name}-mgmt-i"
  network   = google_compute_network.mgmt.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
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
    ["172.16.0.0/12"],
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
    ["172.16.0.0/12"],
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


resource "google_compute_route" "route" {
  count        = 2
  name         = "${var.name}-o-${count.index}"
  dest_range   = "172.16.0.0/12"
  network      = local.data_nets[count.index].id
  next_hop_ilb = google_compute_forwarding_rule.fwdrule[count.index].ip_address
  priority     = 10
}

resource "google_compute_route" "net1-dg" {
  name         = "${var.name}-dg"
  dest_range   = "0.0.0.0/0"
  network      = local.data_nets[1].id
  next_hop_ilb = google_compute_forwarding_rule.fwdrule[1].ip_address
  priority     = 10
}
resource "google_compute_route" "net1-mgmt-exc" {
  for_each         = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr }
  name             = "${var.name}-${each.key}"
  description      = "mgmt traffic exceptions"
  dest_range       = each.value
  network          = local.data_nets[1].id
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
}

