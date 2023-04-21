resource "panos_device_group" "ncc_r" {
  for_each = var.networks["mgmt"]
  name     = "gcp-ncc-${each.key}"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group" "ncc" {
  name = "gcp-ncc"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group_parent" "ncc" {
  device_group = panos_device_group.ncc.name
  parent       = "gcp"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group_parent" "ncc_r" {
  for_each     = var.networks["mgmt"]
  device_group = panos_device_group.ncc_r[each.key].name
  parent       = "gcp-ncc"

  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template" "ncc" {
  name = "gcp-ncc-routing"
}

module "cfg_ncc" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "gcp-ncc-routing"

  interfaces = {
    "ethernet1/1" = {
      static_ips = ["$eth1_1-ipm"]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = ["$eth1_2-ipm"]
      zone       = "internal"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = "$eth1_1-gw"
    }
    sdgw = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = "$eth1_2-gw"
    }
  }
  variables = {
    "eth1_1-gw"        = "192.0.1.1"
    "eth1_1-ip"        = "192.0.1.2"
    "eth1_1-ipm"       = "192.0.1.2/32"
    "eth1_2-gw"        = "192.0.2.1"
    "eth1_2-ip"        = "192.0.2.2"
    "eth1_2-ipm"       = "192.0.2.2/32"
    "cr_internal_p-ip" = "192.0.2.3"
    "cr_internal_r-ip" = "192.0.2.4"
    "cr_internet_p-ip" = "192.0.2.5"
    "cr_internet_r-ip" = "192.0.2.6"
    "local_vpcs"       = "192.0.255.0/24"
  }
  enable_ecmp = false
}

resource "panos_panorama_bgp" "ncc" {
  for_each       = var.networks["mgmt"]
  template       = module.cfg_ncc.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = "$eth1_2-ip"
  as_number = var.asn["fw"]

  allow_redistribute_default_route = true
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer_group" "ncc_internal" {
  template        = module.cfg_ncc.template_name
  virtual_router  = "vr1"
  name            = "ncc-internal"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.ncc
  ]
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer" "ncc_internal_p" {
  template                = module.cfg_ncc.template_name
  name                    = "cr_prv_p"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc_internal.name
  peer_as                 = var.asn["ncc_internal"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2-ipm"
  peer_address_ip         = "$cr_internal_p-ip"
  max_prefixes            = "unlimited"
  multi_hop               = 1
  keep_alive_interval     = var.bgp_keep_alive_interval
  hold_time               = 3 * var.bgp_keep_alive_interval
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer" "ncc_internal_r" {
  template                = module.cfg_ncc.template_name
  name                    = "cr_prv_r"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc_internal.name
  peer_as                 = var.asn["ncc_internal"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2-ipm"
  peer_address_ip         = "$cr_internal_r-ip"
  max_prefixes            = "unlimited"
  multi_hop               = 1
  keep_alive_interval     = var.bgp_keep_alive_interval
  hold_time               = 3 * var.bgp_keep_alive_interval
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer_group" "ncc_internet" {
  template        = module.cfg_ncc.template_name
  virtual_router  = "vr1"
  name            = "ncc-internet"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.ncc
  ]
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer" "ncc_internet_p" {
  template                = module.cfg_ncc.template_name
  name                    = "cr_pub_p"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc_internet.name
  peer_as                 = var.asn["ncc_internet"]
  local_address_interface = "ethernet1/1"
  local_address_ip        = "$eth1_1-ipm"
  peer_address_ip         = "$cr_internet_p-ip"
  max_prefixes            = "unlimited"
  multi_hop               = 1
  keep_alive_interval     = var.bgp_keep_alive_interval
  hold_time               = 3 * var.bgp_keep_alive_interval
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_peer" "ncc_internet_r" {
  template                = module.cfg_ncc.template_name
  name                    = "cr_pub_r"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc_internet.name
  peer_as                 = var.asn["ncc_internet"]
  local_address_interface = "ethernet1/1"
  local_address_ip        = "$eth1_1-ipm"
  peer_address_ip         = "$cr_internet_r-ip"
  max_prefixes            = "unlimited"
  multi_hop               = 1
  keep_alive_interval     = var.bgp_keep_alive_interval
  hold_time               = 3 * var.bgp_keep_alive_interval
  lifecycle { create_before_destroy = true }
}


resource "panos_panorama_bgp_redist_rule" "ncc" {
  template       = module.cfg_ncc.template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = "0.0.0.0/0"

  depends_on = [
    panos_panorama_bgp.ncc
  ]
  lifecycle { create_before_destroy = true }
}


resource "panos_panorama_bgp_export_rule_group" "ncc" {
  template       = module.cfg_ncc.template_name
  virtual_router = "vr1"
  rule {
    name = "dg-for-internal"
    match_address_prefix {
      prefix = "0.0.0.0/0"
      exact  = true
    }
    match_route_table = "unicast"
    action            = "allow"
    used_by = [
      panos_panorama_bgp_peer_group.ncc_internal.name
    ]
  }
  rule {
    name = "local-vpcs"
    match_address_prefix {
      prefix = "$local_vpcs"
      exact  = false
    }
    match_route_table = "unicast"
    action            = "allow"
    used_by = [
      panos_panorama_bgp_peer_group.ncc_internet.name
    ]
  }
  rule {
    name = "all-private"
    match_address_prefix {
      prefix = "172.16.0.0/12"
      exact  = false
    }
    match_route_table = "unicast"
    action            = "allow"
    med               = 20000
    used_by = [
      panos_panorama_bgp_peer_group.ncc_internet.name
    ]
  }
}


resource "panos_panorama_service_object" "s" {
  for_each         = var.global_services
  device_group     = panos_device_group.ncc.name
  name             = "tcp-${each.key}"
  protocol         = "tcp"
  destination_port = each.value
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_nat_rule_group" "ncc_pre_nat" {
  device_group = panos_device_group.ncc.name
  rule {
    name = "default outbound snat"
    original_packet {
      source_zones          = ["internal"]
      destination_zone      = "internet"
      source_addresses      = ["172.16.0.0/12"]
      destination_addresses = ["any"]

    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/1"
          }
        }
      }
      destination {
      }
    }
  }
  rule {
    name = "inbound s1"
    description = format("pub:%s to %s",
      google_compute_global_forwarding_rule.ext["s1"].ip_address,
      panos_panorama_service_object.s["s1"].destination_port
    )
    original_packet {
      source_zones          = ["internet"]
      destination_zone      = "internet"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
      service               = panos_panorama_service_object.s["s1"].name
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
      destination {
        dynamic_translation {
          address = google_compute_instance.srv_app0["europe-west1"].network_interface[0].network_ip
          port    = "80"
        }
      }
    }
  }
  rule {
    name = "inbound s2"
    description = format("pub:%s to %s",
      google_compute_global_forwarding_rule.ext["s2"].ip_address,
      panos_panorama_service_object.s["s2"].destination_port
    )
    original_packet {
      source_zones          = ["internet"]
      destination_zone      = "internet"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
      service               = panos_panorama_service_object.s["s2"].name
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
      destination {
        dynamic_translation {
          address = google_compute_instance.srv_app0["europe-west2"].network_interface[0].network_ip
          port    = "80"
        }
      }
    }
  }
}
