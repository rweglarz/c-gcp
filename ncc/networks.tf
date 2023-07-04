resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
  #routing_mode  = "REGIONAL"
}

resource "google_compute_network" "internet" {
  name                    = "${var.name}-internet"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_network" "internal" {
  name                    = "${var.name}-internal"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_network" "ha" {
  name                    = "${var.name}-ha"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_subnetwork" "mgmt" {
  for_each      = var.networks["mgmt"]
  name          = "${var.name}-mgmt-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.mgmt.id
}

resource "google_compute_subnetwork" "internet" {
  for_each      = var.networks["internet"]
  name          = "${var.name}-internet-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.internet.id
}

resource "google_compute_subnetwork" "internal" {
  for_each      = var.networks["internal"]
  name          = "${var.name}-internal-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.internal.id
}

resource "google_compute_subnetwork" "ha" {
  for_each      = var.networks["ha"]
  name          = "${var.name}-ha-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.ha.id
}


resource "google_compute_network" "srv_app0" {
  name                    = "${var.name}-srv-app0"
  auto_create_subnetworks = "false"

  routing_mode                    = var.vpc_routing_mode
  delete_default_routes_on_create = true
}
resource "google_compute_subnetwork" "srv_app0" {
  for_each      = var.networks["srv_app0"]
  name          = "${var.name}-srv-app0-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.srv_app0.id
}

resource "google_compute_network" "srv_app1" {
  name                    = "${var.name}-srv-app1"
  auto_create_subnetworks = "false"

  routing_mode                    = var.vpc_routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "srv_app1" {
  for_each      = var.networks["srv_app1"]
  name          = "${var.name}-srv-app1-${each.key}"
  region        = each.key
  ip_cidr_range = cidrsubnet(var.cidr, 5, each.value.idx)
  network       = google_compute_network.srv_app1.id
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
resource "google_compute_firewall" "srv_app0-i" {
  name      = "${var.name}-srv-app0-i"
  network   = google_compute_network.srv_app0.id
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
resource "google_compute_firewall" "srv_app1-i" {
  name      = "${var.name}-srv-app1-i"
  network   = google_compute_network.srv_app1.id
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


# resource "google_compute_route" "srv0-dg" {
#   name         = "${var.name}-srv0-dg"
#   dest_range   = "0.0.0.0/0"
#   network      = google_compute_network.srv0.id
#   next_hop_ilb = google_compute_forwarding_rule.internal.ip_address
#   priority     = 10
# }
# resource "google_compute_route" "srv1-dg" {
#   name         = "${var.name}-srv1-dg"
#   dest_range   = "0.0.0.0/0"
#   network      = google_compute_network.srv1.id
#   next_hop_ilb = google_compute_forwarding_rule.internal.ip_address
#   priority     = 10
# }


resource "google_compute_route" "srv0-mgmt-exc" {
  for_each         = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr if length(regexall("jumphost", e.description))==0}
  name             = "${var.name}-srv-app0-${each.key}"
  description      = "srv0 traffic exceptions"
  dest_range       = each.value
  network          = google_compute_network.srv_app0.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
}

resource "google_compute_route" "srv1-mgmt-exc" {
  for_each         = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr if length(regexall("jumphost", e.description))==0}
  name             = "${var.name}-srv-app1-${each.key}"
  description      = "srv1 traffic exceptions"
  dest_range       = each.value
  network          = google_compute_network.srv_app1.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
}


resource "google_compute_network_peering" "internal-srv_app0" {
  name                 = "${var.name}-internal-srv-app0"
  network              = google_compute_network.internal.self_link
  peer_network         = google_compute_network.srv_app0.self_link
  export_custom_routes = true
  depends_on = [
    google_compute_route.srv0-mgmt-exc,
  ]
}
resource "google_compute_network_peering" "srv_app0-internal" {
  name                 = "${var.name}-srv-app0-internal"
  network              = google_compute_network.srv_app0.self_link
  peer_network         = google_compute_network.internal.self_link
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.internal-srv_app0
  ]
}
resource "google_compute_network_peering" "internal-srv_app1" {
  name                 = "${var.name}-internal-srv-app1"
  network              = google_compute_network.internal.self_link
  peer_network         = google_compute_network.srv_app1.self_link
  export_custom_routes = true
  depends_on = [
    google_compute_route.srv1-mgmt-exc,
    google_compute_network_peering.srv_app0-internal,
  ]
}
resource "google_compute_network_peering" "srv_app1-internal" {
  name                 = "${var.name}-srv-app1-internal"
  network              = google_compute_network.srv_app1.self_link
  peer_network         = google_compute_network.internal.self_link
  import_custom_routes = true
  depends_on = [
    google_compute_network_peering.internal-srv_app1
  ]
}
