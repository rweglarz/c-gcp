resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = cidrsubnet(var.cidr, 5, 0)
  network       = google_compute_network.mgmt.id
}

resource "google_compute_network" "public" {
  name                    = "${var.name}-public"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-public-s"
  ip_cidr_range = cidrsubnet(var.cidr, 5, 1)
  network       = google_compute_network.public.id
}

resource "google_compute_network" "data_nets" {
  count                   = var.vpc_count
  name                    = "${var.name}-n${count.index+2}"
  auto_create_subnetworks = "false"
}
locals {
  data_nets_cidr = {
     for k,v in google_compute_network.data_nets: k => cidrsubnet(var.cidr, 5, 2+k)
  }
  peered_net_v0_cidr = {
     for k,v in google_compute_network.peered_net_v0: k => cidrsubnet(var.cidr, 5, 8+2*k)
  }
  peered_net_v1_cidr = {
     for k,v in google_compute_network.peered_net_v1: k => cidrsubnet(var.cidr, 5, 8+2*k+1)
  }
}
resource "google_compute_subnetwork" "data_subnet_fw" {
  count         = var.vpc_count
  name          = "${var.name}-data-n${count.index+2}-fw"
  ip_cidr_range = cidrsubnet(local.data_nets_cidr[count.index], 2, 0)
  network       = google_compute_network.data_nets[count.index].id
}
resource "google_compute_subnetwork" "data_subnet_s0" {
  count         = var.vpc_count
  name          = "${var.name}-data-n${count.index+2}-s0"
  ip_cidr_range = cidrsubnet(local.data_nets_cidr[count.index], 2, 1)
  network       = google_compute_network.data_nets[count.index].id
}
resource "google_compute_subnetwork" "data_subnet_s1" {
  count         = var.vpc_count
  name          = "${var.name}-data-n${count.index+2}-s1"
  ip_cidr_range = cidrsubnet(local.data_nets_cidr[count.index], 2, 2)
  network       = google_compute_network.data_nets[count.index].id
}

resource "google_compute_network" "peered_net_v0" {
  count                   = var.vpc_count
  name                    = "${var.name}-p${count.index+2}-v0"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "peered_subnet_v0_s0" {
  count         = var.vpc_count
  name          = "${var.name}-p${count.index+2}-v0-s0"
  ip_cidr_range = cidrsubnet(local.peered_net_v0_cidr[count.index], 2, 0)
  network       = google_compute_network.peered_net_v0[count.index].id
}


resource "google_compute_network" "peered_net_v1" {
  count                   = var.vpc_count
  name                    = "${var.name}-p${count.index+2}-v1"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "peered_subnet_v1_s0" {
  count         = var.vpc_count
  name          = "${var.name}-p${count.index+2}-v1-s0"
  ip_cidr_range = cidrsubnet(local.peered_net_v1_cidr[count.index], 2, 0)
  network       = google_compute_network.peered_net_v1[count.index].id
}


resource "google_compute_router" "router" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "cloud_nat" {
  name   = "${var.name}-nat-ip"
  region = google_compute_subnetwork.mgmt.region
}

resource "google_compute_router_nat" "router_nat" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_router" "router_public" {
  name    = "${var.name}-rtr-public"
  network = google_compute_network.public.id
}

resource "google_compute_router_nat" "router_public_nat" {
  name   = "${var.name}-rtr-public-nat"
  router = google_compute_router.router_public.name

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
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



resource "google_compute_firewall" "public-i" {
  name      = "${var.name}-public-i"
  network   = google_compute_network.public.id
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "mgmt-e" {
  name      = "${var.name}-mgmt-e"
  network   = google_compute_network.mgmt.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "data-i" {
  count     = var.vpc_count
  name      = "${var.name}-n${count.index+2}-i"
  direction = "INGRESS"
  network   = google_compute_network.data_nets[count.index].id
  source_ranges = [
    "0.0.0.0/0",
  ]
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "data-e" {
  count     = var.vpc_count
  name      = "${var.name}-n${count.index+2}-e"
  direction = "EGRESS"
  network   = google_compute_network.data_nets[count.index].id
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "peered-v0-i" {
  count     = var.vpc_count
  name      = "${var.name}-p${count.index}-v0-i"
  direction = "INGRESS"
  network   = google_compute_network.peered_net_v0[count.index].id
  source_ranges = [
    "0.0.0.0/0",
  ]
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "peered-v0-e" {
  count     = var.vpc_count
  name      = "${var.name}-p${count.index}-v0-e"
  direction = "EGRESS"
  network   = google_compute_network.peered_net_v0[count.index].id
  allow {
    protocol = "all"
  }
}




resource "google_compute_network_peering" "data-peered-v0" {
  count                = var.vpc_count
  name                 = "${var.name}-data--p${count.index}-v0"
  network              = google_compute_network.data_nets[count.index].self_link
  peer_network         = google_compute_network.peered_net_v0[count.index].self_link
  export_custom_routes = true
}
resource "google_compute_network_peering" "peered-v0-data" {
  count                = var.vpc_count
  name                 = "${var.name}-peered${count.index}-v0--data"
  network              = google_compute_network.peered_net_v0[count.index].self_link
  peer_network         = google_compute_network.data_nets[count.index].self_link
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.data-peered-v0
  ]
}


resource "google_compute_network_peering" "data-peered-v1" {
  count                = var.vpc_count
  name                 = "${var.name}-data--p${count.index}-v1"
  network              = google_compute_network.data_nets[count.index].self_link
  peer_network         = google_compute_network.peered_net_v1[count.index].self_link
  export_custom_routes = true
}
resource "google_compute_network_peering" "peered-v1-data" {
  count                = var.vpc_count
  name                 = "${var.name}-peered${count.index}-v1--data"
  network              = google_compute_network.peered_net_v1[count.index].self_link
  peer_network         = google_compute_network.data_nets[count.index].self_link
  import_custom_routes = true

  depends_on = [
    google_compute_network_peering.data-peered-v1
  ]
}

