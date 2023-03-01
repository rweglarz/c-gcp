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

resource "panos_panorama_template" "ha" {
  name = "gcp-ha"
}
resource "panos_panorama_template_stack" "ha_fw0" {
  name         = "gcp-ha-fw0"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha.name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
}
resource "panos_panorama_template_stack" "ha_fw1" {
  name         = "gcp-ha-fw1"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha.name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
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


resource "panos_panorama_management_profile" "ha_ping" {
  template = panos_panorama_template.ha.name
  name     = "ping"
  ping     = true
}
resource "panos_panorama_management_profile" "ha_hc" {
  template = panos_panorama_template.ha.name
  name     = "hc"
  ping     = true
  http     = true
  https    = true
}
resource "panos_panorama_ethernet_interface" "ha_eth1_1" {
  template = panos_panorama_template.ha.name
  name     = "ethernet1/1"
  vsys     = "vsys1"
  mode     = "layer3"

  enable_dhcp               = true
  create_dhcp_default_route = true

  management_profile = panos_panorama_management_profile.ha_hc.name
}
resource "panos_panorama_ethernet_interface" "ha_eth1_2" {
  template = panos_panorama_template.ha.name
  name     = "ethernet1/2"
  vsys     = "vsys1"
  mode     = "layer3"

  enable_dhcp               = true
  create_dhcp_default_route = false

  management_profile = panos_panorama_management_profile.ha_hc.name
}
resource "panos_panorama_loopback_interface" "ha_lo1" {
  template = panos_panorama_template.ha.name
  name     = "loopback.1"
  static_ips = [
    "${google_compute_forwarding_rule.ext.ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.ha_hc.name
}
resource "panos_panorama_loopback_interface" "ha_lo2" {
  template = panos_panorama_template.ha.name
  name     = "loopback.2"
  static_ips = [
    "${google_compute_forwarding_rule.internal.ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.ha_hc.name
}

resource "panos_panorama_loopback_interface" "ha_lo99" {
  template = panos_panorama_template.ha.name
  name     = "loopback.99"
  static_ips = [
    "192.168.1.1/32",
  ]
  management_profile = panos_panorama_management_profile.ha_ping.name
}



resource "panos_virtual_router" "ha_vr1" {
  name     = "vr1"
  template = panos_panorama_template.ha.name

  enable_ecmp           = true
  ecmp_symmetric_return = true
  ecmp_max_path         = 4

  interfaces = [
    panos_panorama_ethernet_interface.ha_eth1_1.name,
    panos_panorama_ethernet_interface.ha_eth1_2.name,
    panos_panorama_loopback_interface.ha_lo1.name,
    panos_panorama_loopback_interface.ha_lo2.name,
    panos_panorama_loopback_interface.ha_lo99.name,
  ]
}

resource "panos_panorama_static_route_ipv4" "ha_vr1_172" {
  template       = panos_panorama_template.ha.name
  virtual_router = panos_virtual_router.ha_vr1.name
  name           = "internal"
  destination    = "172.16.0.0/12"
  interface      = panos_panorama_ethernet_interface.ha_eth1_2.name
  next_hop       = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1)
}


locals {
  lb_hc = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    #    "209.85.152.0/22",
    #    "209.85.204.0/22",
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

resource "panos_panorama_static_route_ipv4" "ha_vr1_25_191" {
  for_each       = { for r in local.lb_hc_routes : r.n => r }
  template       = panos_panorama_template.ha.name
  virtual_router = panos_virtual_router.ha_vr1.name
  name           = each.key
  destination    = each.value.dst
  interface      = each.value.int
  next_hop       = each.value.nh
}

resource "panos_zone" "ha_internet" {
  template = panos_panorama_template.ha.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha_eth1_1.name,
    panos_panorama_loopback_interface.ha_lo1.name,
  ]
}
resource "panos_zone" "ha_private" {
  template = panos_panorama_template.ha.name
  name     = "private"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha_eth1_2.name,
    panos_panorama_loopback_interface.ha_lo2.name,
    panos_panorama_loopback_interface.ha_lo99.name,
  ]
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
      source_zones          = [panos_zone.ha_private.name]
      destination_zone      = panos_zone.ha_internet.name
      source_addresses      = ["172.16.0.0/12"]
      destination_addresses = ["any"]

    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = panos_panorama_loopback_interface.ha_lo1.name
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
      source_zones          = [panos_zone.ha_internet.name]
      destination_zone      = panos_zone.ha_internet.name
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
    name                  = "outbound"
    source_zones          = [panos_zone.ha_private.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = [panos_zone.ha_internet.name]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = var.log_forwarding
  }
  rule {
    name                  = "inbound srv0"
    source_zones          = [panos_zone.ha_internet.name]
    source_addresses      = [var.test_client_ip]
    source_users          = ["any"]
    destination_zones     = [panos_zone.ha_private.name]
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
