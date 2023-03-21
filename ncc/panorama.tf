resource "panos_device_group" "ncc" {
  name = "gcp-ncc"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group_parent" "ncc" {
  device_group = panos_device_group.ncc.name
  parent       = "gcp"

  lifecycle { create_before_destroy = true }
}

module "cfg_fwp" {
  for_each = var.networks["mgmt"]
  source   = "../../ce-common/modules/pan_vm_template"

  name = "gcp-ncc-fwp-${each.key}-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.fwp[each.key].eth1_1_ip, local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.fwp[each.key].eth1_2_ip, local.subnet_prefix_length)]
      zone       = "internal"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.fwp[each.key].eth1_1_gw
    }
    sdgw = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.fwp[each.key].eth1_2_gw
    }
  }
  enable_ecmp = false
}

resource "panos_panorama_template_stack" "fwp" {
  for_each     = var.networks["mgmt"]
  name         = "gcp-ncc-fwp-${each.key}"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fwp[each.key].template_name,
    "vm common",
  ]
  description = "pat:acp"
}


resource "panos_panorama_bgp" "fwp" {
  for_each       = var.networks["mgmt"]
  template       = module.cfg_fwp[each.key].template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = local.private_ips.fwp[each.key].eth1_2_ip
  as_number = var.asn["fw"]

  allow_redistribute_default_route = true
}

resource "panos_panorama_bgp_peer_group" "ncc" {
  for_each        = var.networks["mgmt"]
  template        = module.cfg_fwp[each.key].template_name
  virtual_router  = "vr1"
  name            = "ncc"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.fwp
  ]
}

resource "panos_panorama_bgp_peer" "ncc_p" {
  for_each                = var.networks["mgmt"]
  template                = module.cfg_fwp[each.key].template_name
  name                    = "ncc_p"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc[each.key].name
  peer_as                 = var.asn["ncc"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.fwp[each.key].eth1_2_ip, local.subnet_prefix_length)
  peer_address_ip         = local.private_ips.cr_int[each.key].intf_p_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "ncc_r" {
  for_each                = var.networks["mgmt"]
  template                = module.cfg_fwp[each.key].template_name
  name                    = "ncc_r"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.ncc[each.key].name
  peer_as                 = var.asn["ncc"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.fwp[each.key].eth1_2_ip, local.subnet_prefix_length)
  peer_address_ip         = local.private_ips.cr_int[each.key].intf_r_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_redist_rule" "ncc" {
  for_each       = var.networks["mgmt"]
  template       = module.cfg_fwp[each.key].template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = "0.0.0.0/0"

  lifecycle { create_before_destroy = true }
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
}
