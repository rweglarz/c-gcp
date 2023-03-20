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
  for_each = var.networks["mgmt"]
  name         = "gcp-ncc-fwp-${each.key}"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fwp[each.key].template_name,
    "vm common",
  ]
  description = "pat:acp"
}

