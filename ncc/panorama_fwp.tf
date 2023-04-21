resource "panos_panorama_template_stack" "fwp" {
  for_each     = var.networks["mgmt"]
  name         = "gcp-ncc-fwp-${each.key}"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ncc.name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
}

locals {
  fwp_variable_map = flatten([
    for lk, lv in var.networks["mgmt"] : [
      for vk, vv in {
        eth1_1-gw        = local.private_ips.fwp[lk].eth1_1_gw
        eth1_1-ip        = local.private_ips.fwp[lk].eth1_1_ip
        eth1_1-ipm       = format("%s/%s", local.private_ips.fwp[lk].eth1_1_ip, local.subnet_prefix_length)
        eth1_2-gw        = local.private_ips.fwp[lk].eth1_2_gw
        eth1_2-ip        = local.private_ips.fwp[lk].eth1_2_ip
        eth1_2-ipm       = format("%s/%s", local.private_ips.fwp[lk].eth1_2_ip, local.subnet_prefix_length)
        cr_internal_p-ip = local.private_ips.cr_internal[lk].intf_p_ip
        cr_internal_r-ip = local.private_ips.cr_internal[lk].intf_r_ip
        cr_internet_p-ip = local.private_ips.cr_internet[lk].intf_p_ip
        cr_internet_r-ip = local.private_ips.cr_internet[lk].intf_r_ip
        ha1-peer-ip      = local.private_ips.fws[lk].mgmt_ip
        ha2-local-ip     = local.private_ips.fwp[lk].eth1_3_ip
        ha2-gw           = local.private_ips.fwp[lk].eth1_3_gw
        local_vpcs       = local.local_vpcs[lk]
        } : {
        k     = format("%s-%s", lk, vk)
        ts    = panos_panorama_template_stack.fwp[lk].name
        name  = vk
        value = vv
      }
    ]
  ])
}

resource "panos_panorama_template_variable" "fwp" {
  for_each = { for e in local.fwp_variable_map : e.k => e }

  template_stack = each.value.ts
  name           = "${"$"}${each.value.name}"
  type           = "ip-netmask"
  value          = each.value.value
}

