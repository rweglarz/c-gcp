resource "google_network_connectivity_hub" "this" {
  name = "${var.name}-hub"
}

resource "google_network_connectivity_spoke" "internal" {
  for_each = var.networks["internal"]
  name     = "${var.name}-internal-${each.key}"
  hub      = google_network_connectivity_hub.this.id
  location = each.key

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.fwp[each.key].self_link
      ip_address      = google_compute_instance.fwp[each.key].network_interface[2].network_ip
    }
    instances {
      virtual_machine = google_compute_instance.fws[each.key].self_link
      ip_address      = google_compute_instance.fws[each.key].network_interface[2].network_ip
    }
    site_to_site_data_transfer = false
  }
}

resource "google_compute_router" "internal" {
  for_each = var.networks["internal"]
  name     = "internal-${each.key}"
  network  = google_compute_network.internal.name
  region   = each.key
  bgp {
    asn               = var.asn.ncc_internal
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = cidrsubnet(var.cidr, 1, 0)
    }
    advertised_ip_ranges {
      range = cidrsubnet(var.cidr, 1, 1)
    }
    advertised_ip_ranges {
      range = "172.16.0.0/12"
    }
  }
}


resource "google_compute_router_interface" "internal_intf_r" {
  for_each           = var.networks["internal"]
  name               = "internal-r-${each.key}"
  region             = each.key
  router             = google_compute_router.internal[each.key].name
  subnetwork         = google_compute_subnetwork.internal[each.key].self_link
  private_ip_address = local.private_ips.cr_internal[each.key].intf_r_ip
}

resource "google_compute_router_interface" "internal_intf_p" {
  for_each            = var.networks["internal"]
  name                = "internal-p-${each.key}"
  region              = each.key
  router              = google_compute_router.internal[each.key].name
  subnetwork          = google_compute_subnetwork.internal[each.key].self_link
  private_ip_address  = local.private_ips.cr_internal[each.key].intf_p_ip
  redundant_interface = google_compute_router_interface.internal_intf_r[each.key].name
}

resource "google_compute_router_peer" "internal_p_fwp" {
  for_each                  = google_compute_instance.fwp
  name                      = "p-${each.key}-fwp"
  router                    = google_compute_router.internal[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internal_intf_p[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fwp[each.key].self_link
  peer_ip_address           = local.private_ips.fwp[each.key].eth1_2_ip
}

resource "google_compute_router_peer" "internal_r_fwp" {
  for_each                  = google_compute_instance.fwp
  name                      = "r-${each.key}-fwp"
  router                    = google_compute_router.internal[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internal_intf_r[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fwp[each.key].self_link
  peer_ip_address           = local.private_ips.fwp[each.key].eth1_2_ip
}


resource "google_compute_router_peer" "internal_p_fws" {
  for_each                  = google_compute_instance.fws
  name                      = "p-${each.key}-fws"
  router                    = google_compute_router.internal[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internal_intf_p[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fws[each.key].self_link
  peer_ip_address           = local.private_ips.fws[each.key].eth1_2_ip
}

resource "google_compute_router_peer" "internal_r_fws" {
  for_each                  = google_compute_instance.fws
  name                      = "r-${each.key}-fws"
  router                    = google_compute_router.internal[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internal_intf_r[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fws[each.key].self_link
  peer_ip_address           = local.private_ips.fws[each.key].eth1_2_ip
}


resource "google_network_connectivity_spoke" "internet" {
  for_each = var.networks["internet"]
  name     = "${var.name}-internet-${each.key}"
  hub      = google_network_connectivity_hub.this.id
  location = each.key

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.fwp[each.key].self_link
      ip_address      = google_compute_instance.fwp[each.key].network_interface[0].network_ip
    }
    instances {
      virtual_machine = google_compute_instance.fws[each.key].self_link
      ip_address      = google_compute_instance.fws[each.key].network_interface[0].network_ip
    }
    site_to_site_data_transfer = false
  }
}

resource "google_compute_router" "internet" {
  for_each = var.networks["internet"]
  name     = "internet-${each.key}"
  network  = google_compute_network.internet.name
  region   = each.key
  bgp {
    asn               = var.asn.ncc_internet
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    # advertised_ip_ranges {
    #   range = "10.0.0.1"
    # }
    # advertised_ip_ranges {
    #   range = "10.0.1.0/24"
    # }
  }
}


resource "google_compute_router_interface" "internet_intf_r" {
  for_each           = var.networks["internet"]
  name               = "internet-r-${each.key}"
  region             = each.key
  router             = google_compute_router.internet[each.key].name
  subnetwork         = google_compute_subnetwork.internet[each.key].self_link
  private_ip_address = local.private_ips.cr_internet[each.key].intf_r_ip
}

resource "google_compute_router_interface" "internet_intf_p" {
  for_each            = var.networks["internet"]
  name                = "internet-p-${each.key}"
  region              = each.key
  router              = google_compute_router.internet[each.key].name
  subnetwork          = google_compute_subnetwork.internet[each.key].self_link
  private_ip_address  = local.private_ips.cr_internet[each.key].intf_p_ip
  redundant_interface = google_compute_router_interface.internet_intf_r[each.key].name
}

resource "google_compute_router_peer" "internet_p_fwp" {
  for_each                  = google_compute_instance.fwp
  name                      = "p-${each.key}-fwp"
  router                    = google_compute_router.internet[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internet_intf_p[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fwp[each.key].self_link
  peer_ip_address           = local.private_ips.fwp[each.key].eth1_1_ip
}

resource "google_compute_router_peer" "internet_r_fwp" {
  for_each                  = google_compute_instance.fwp
  name                      = "r-${each.key}-fwp"
  router                    = google_compute_router.internet[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internet_intf_r[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fwp[each.key].self_link
  peer_ip_address           = local.private_ips.fwp[each.key].eth1_1_ip
}


resource "google_compute_router_peer" "internet_p_fws" {
  for_each                  = google_compute_instance.fws
  name                      = "p-${each.key}-fws"
  router                    = google_compute_router.internet[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internet_intf_p[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fws[each.key].self_link
  peer_ip_address           = local.private_ips.fws[each.key].eth1_1_ip
}

resource "google_compute_router_peer" "internet_r_fws" {
  for_each                  = google_compute_instance.fws
  name                      = "r-${each.key}-fws"
  router                    = google_compute_router.internet[each.key].name
  region                    = each.key
  interface                 = google_compute_router_interface.internet_intf_r[each.key].name
  peer_asn                  = var.asn.fw
  router_appliance_instance = google_compute_instance.fws[each.key].self_link
  peer_ip_address           = local.private_ips.fws[each.key].eth1_1_ip
}



resource "google_compute_router_nat" "internet_nat" {
  for_each = var.networks["internet"]
  name     = "${var.name}-rtr-internet-snat-${each.key}"
  router   = google_compute_router.internet[each.key].name
  region   = each.key

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
