resource "panos_panorama_template" "ncc" {
  name = "gcp-ncc"
}
resource "panos_panorama_template_stack" "ncc_fw0" {
  name         = "gcp-ncc-fw0"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ncc.name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
}
resource "panos_panorama_template_stack" "ncc_fw1" {
  name         = "gcp-ncc-fw1"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ncc.name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
}

resource "panos_panorama_template_variable" "ncc_fw0-peer_ip" {
  template_stack = panos_panorama_template_stack.ncc_fw0.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[1].network_interface[1].network_ip
}
resource "panos_panorama_template_variable" "ncc_fw1-peer_ip" {
  template_stack = panos_panorama_template_stack.ncc_fw1.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[0].network_interface[1].network_ip
}
resource "panos_panorama_template_variable" "ncc_fw0-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.ncc_fw0.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[0].network_interface[3].network_ip
}
resource "panos_panorama_template_variable" "ncc_fw1-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.ncc_fw1.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = google_compute_instance.fw[1].network_interface[3].network_ip
}
resource "panos_panorama_template_variable" "ncc_fw0-ha2_gw" {
  template_stack = panos_panorama_template_stack.ncc_fw0.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(google_compute_subnetwork.ha.ip_cidr_range, 1)
}
resource "panos_panorama_template_variable" "ncc_fw1-ha2_gw" {
  template_stack = panos_panorama_template_stack.ncc_fw1.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(google_compute_subnetwork.ha.ip_cidr_range, 1)
}


resource "panos_panorama_management_profile" "ncc_ping" {
  template = panos_panorama_template.ncc.name
  name     = "ping"
  ping     = true
}
resource "panos_panorama_management_profile" "ncc_hc" {
  template = panos_panorama_template.ncc.name
  name     = "hc"
  ping     = true
  http     = true
  https    = true
}
resource "panos_panorama_ethernet_interface" "ncc_eth1_1" {
  template = panos_panorama_template.ncc.name
  name     = "ethernet1/1"
  vsys     = "vsys1"
  mode     = "layer3"

  enable_dhcp               = true
  create_dhcp_default_route = true

  management_profile = panos_panorama_management_profile.ncc_hc.name
}
resource "panos_panorama_ethernet_interface" "ncc_eth1_2" {
  template = panos_panorama_template.ncc.name
  name     = "ethernet1/2"
  vsys     = "vsys1"
  mode     = "layer3"

  enable_dhcp               = true
  create_dhcp_default_route = false

  management_profile = panos_panorama_management_profile.ncc_hc.name
}
resource "panos_panorama_loopback_interface" "ncc_lo1" {
  template = panos_panorama_template.ncc.name
  name     = "loopback.1"
  static_ips = [
    "${google_compute_forwarding_rule.ext.ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.ncc_hc.name
}
resource "panos_panorama_loopback_interface" "ncc_lo2" {
  template = panos_panorama_template.ncc.name
  name     = "loopback.2"
  static_ips = [
    "${google_compute_forwarding_rule.internal.ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.ncc_hc.name
}



resource "panos_virtual_router" "ncc_vr1" {
  name     = "vr1"
  template = panos_panorama_template.ncc.name

  enable_ecmp           = true
  ecmp_symmetric_return = true
  ecmp_max_path         = 4

  interfaces = [
    panos_panorama_ethernet_interface.ncc_eth1_1.name,
    panos_panorama_ethernet_interface.ncc_eth1_2.name,
    panos_panorama_loopback_interface.ncc_lo1.name,
    panos_panorama_loopback_interface.ncc_lo2.name,
  ]
}

resource "panos_panorama_static_route_ipv4" "ncc_vr1_172" {
  template       = panos_panorama_template.ncc.name
  virtual_router = panos_virtual_router.ncc_vr1.name
  name           = "internal"
  destination    = "172.16.0.0/12"
  interface      = panos_panorama_ethernet_interface.ncc_eth1_2.name
  next_hop       = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 1)
}


locals {
  lb_hc = [
    "35.191.0.0/16",
    "130.211.0.0/22",
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

resource "panos_panorama_static_route_ipv4" "ncc_vr1_25_191" {
  for_each       = { for r in local.lb_hc_routes : r.n => r }
  template       = panos_panorama_template.ncc.name
  virtual_router = panos_virtual_router.ncc_vr1.name
  name           = each.key
  destination    = each.value.dst
  interface      = each.value.int
  next_hop       = each.value.nh
}

resource "panos_zone" "ncc_internet" {
  template = panos_panorama_template.ncc.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ncc_eth1_1.name,
    panos_panorama_loopback_interface.ncc_lo1.name,
  ]
}
resource "panos_zone" "ncc_private" {
  template = panos_panorama_template.ncc.name
  name     = "private"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ncc_eth1_2.name,
    panos_panorama_loopback_interface.ncc_lo2.name,
  ]
}
