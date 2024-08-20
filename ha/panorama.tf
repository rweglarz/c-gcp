resource "panos_device_group" "ha" {
  name = "gcp-ha"

  lifecycle {
    create_before_destroy = true
  }
}
resource "panos_device_group_parent" "ha" {
  device_group = panos_device_group.ha.name
  parent       = "gcp"

  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_template_stack" "ha_fw0" {
  name         = "gcp-ha-fw0"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fw.template_name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
}
resource "panos_panorama_template_stack" "ha_fw1" {
  name         = "gcp-ha-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fw.template_name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
}



module "cfg_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "gcp-ha-t"

  interfaces = {
    "ethernet1/1" = {
      enable_dhcp               = true
      create_dhcp_default_route = false

      zone               = "internet"
      management_profile = "https"
    }
    "ethernet1/2" = {
      enable_dhcp               = true
      create_dhcp_default_route = false

      zone               = "private"
      management_profile = "https"
    }
    "loopback.1" = {
      static_ips = [ "${google_compute_forwarding_rule.ext.ip_address}/32" ]

      zone               = "internet"
      management_profile = "https"
    }
    "loopback.2" = {
      static_ips = [ "${google_compute_forwarding_rule.internal.ip_address}/32" ]

      zone               = "private"
      management_profile = "https"
    }
    "loopback.99" = {
      static_ips = [ "192.168.1.1/32" ]

      zone               = "private"
      management_profile = "ping"
    }
    "tunnel.10" = {
      static_ips = [ "192.168.255.100/32" ]
      zone = "vpn-linux-0"
    }
    "tunnel.11" = {
      static_ips = [ "192.168.255.110/32" ]
      zone = "vpn-linux-1"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(google_compute_subnetwork.internet.ip_cidr_range, 1)
    }
    i10 = {
      destination = "10.0.0.0/8"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1)
    }
    i172 = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1)
    }
    i192 = {
      destination = "192.168.0.0/16"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1)
    }
  }

  enable_ecmp = true
}



resource "panos_panorama_template_variable" "ha_fw0-peer_ip" {
  template_stack = panos_panorama_template_stack.ha_fw0.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[1].network_interface[1].network_ip
}
resource "panos_panorama_template_variable" "ha_fw1-peer_ip" {
  template_stack = panos_panorama_template_stack.ha_fw1.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[0].network_interface[1].network_ip
}
resource "panos_panorama_template_variable" "ha_fw0-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.ha_fw0.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[0].network_interface[3].network_ip
}
resource "panos_panorama_template_variable" "ha_fw1-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.ha_fw1.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[1].network_interface[3].network_ip
}
resource "panos_panorama_template_variable" "ha_fw0-ha2_gw" {
  template_stack = panos_panorama_template_stack.ha_fw0.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(google_compute_subnetwork.ha.ip_cidr_range, 1)
}
resource "panos_panorama_template_variable" "ha_fw1-ha2_gw" {
  template_stack = panos_panorama_template_stack.ha_fw1.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(google_compute_subnetwork.ha.ip_cidr_range, 1)
}


locals {
  lb_hc = [
    "35.191.0.0/16",
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]
  int_nh = [
    {
      i = "ethernet1/1"
      d = cidrhost(google_compute_subnetwork.internet.ip_cidr_range, 1),
    },
    {
      i = "ethernet1/2"
      d = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1),
    }
  ]
  lb_hc_routes = flatten([
    for r in local.lb_hc : [
      for id in local.int_nh : {
        n   = replace(format("%s_%s", id.i, r), "/\\//", "_")
        dst = r
        int = id.i
        nh  = id.d
      }
    ]
  ])
}



module "tunnel-linux" {
  source = "../../ce-common/modules/pan_tunnel"
  count  = 2

  peers = {
    left = {
      name = "fw"
      ip   = google_compute_forwarding_rule.ext.ip_address
      interface = {
        phys   = "loopback.1"
        tunnel = count.index==0 ? "tunnel.10" : "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = google_compute_forwarding_rule.ext.ip_address
      }
      template = module.cfg_fw.template_name
    }
    right = {
      name = "linux${count.index}"
      ip   = google_compute_address.linux[count.index].address
      interface = {
        phys   = "loopback.1"
        tunnel = count.index==0 ? "tunnel.10" : "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = google_compute_address.linux[count.index].address
      }
      template = module.cfg_fw.template_name
      do_not_configure = true
    }
  }
  psk = var.vpn_psk
}




resource "panos_panorama_static_route_ipv4" "ha_vr1_25_191" {
  for_each       = { for r in local.lb_hc_routes : r.n => r }
  template       = module.cfg_fw.template_name
  virtual_router = module.cfg_fw.vr_name
  name           = each.key
  destination    = each.value.dst
  interface      = each.value.int
  next_hop       = each.value.nh
}


resource "panos_panorama_service_object" "ha_ssh_22" {
  device_group     = panos_device_group.ha.name
  name             = "ha-ssh-22"
  protocol         = "tcp"
  destination_port = "22"
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_nat_rule_group" "ha_pre_nat" {
  device_group = panos_device_group.ha.name
  rule {
    name = "default outbound snat"
    original_packet {
      source_zones          = ["private"]
      destination_zone      = "internet"
      source_addresses      = ["172.16.0.0/12"]
      destination_addresses = ["any"]

    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "loopback.1"
          }
        }
      }
      destination {
      }
    }
  }
  rule {
    name = "inbound srv0"
    original_packet {
      source_zones          = ["internet"]
      destination_zone      = "internet"
      source_addresses      = ["any"]
      destination_addresses = [google_compute_forwarding_rule.ext.ip_address]
      service               = panos_panorama_service_object.ha_ssh_22.name
    }
    translated_packet {
      source {
      }
      destination {
        static_translation {
          address = google_compute_instance.srv0.network_interface[0].network_ip
        }
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_security_rule_group" "ha_pre_sec" {
  device_group = panos_device_group.ha.name
  rule {
    name                  = "ipsec"
    source_zones          = ["internet"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["internet"]
    destination_addresses = ["any"]
    applications          = ["ipsec", "ping"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = var.log_forwarding
    log_start             = true
    log_end               = true
  }
  rule {
    name                  = "outbound"
    source_zones          = ["private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["internet"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = var.log_forwarding
  }
  rule {
    name                  = "inbound srv0"
    source_zones          = ["internet"]
    source_addresses      = [var.test_client_ip]
    source_users          = ["any"]
    destination_zones     = ["private"]
    destination_addresses = [google_compute_forwarding_rule.ext.ip_address]
    applications          = ["any"]
    services              = [panos_panorama_service_object.ha_ssh_22.name]
    categories            = ["any"]
    action                = "allow"
    log_setting           = var.log_forwarding
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_pbf_rule_group" "ha" {
  device_group = panos_device_group.ha.name
  rule {
    name = "linux inbound"
    source {
      interfaces = [
        "tunnel.10",
        "tunnel.11",
      ]
      addresses = ["any"]
      users     = ["any"]
    }
    destination {
      addresses    = ["any"]
      applications = ["any"]
      services     = ["any"]
    }
    forwarding {
      action = "no-pbf"
      symmetric_return {
        enable = true
      }
    }
  }
}
