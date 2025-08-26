resource "google_network_connectivity_policy_based_route" "a-fw" {
  name = "${var.name}-private-a-fw"
  description = "firewalls in private-a"
  network = google_compute_network.private["a"].id
  priority = 1

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
  }
  next_hop_other_routes = "DEFAULT_ROUTING"

  virtual_machine {
    tags = [
      "firewalls"
    ]
  }
}

resource "google_network_connectivity_policy_based_route" "a" {
  for_each = merge(
    { 
      private-a = google_compute_network.private["a"].id
    },
    { for k,v in google_compute_network.peer: k=>v.id if strcontains(k, "private-a") },
  )
  name = "${var.name}-${each.key}"
  description = "workloads in ${each.key}"
  network = each.value
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.private["a"].ip_address
}

resource "google_network_connectivity_policy_based_route" "b" {
  for_each = merge(
    { 
      private-b = google_compute_network.private["b"].id
    },
    { for k,v in google_compute_network.peer: k=>v.id if strcontains(k, "private-b") },
  )

  name = "${var.name}-${each.key}"
  description = "workloads in ${each.key}"
  network = each.value
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.private["b"].ip_address
}



resource "google_network_connectivity_policy_based_route" "privatevpn-aa--ab" {
  name = "${var.name}-privatevpn-aa-to-ab"
  description = "vpns in private-a"
  network = google_compute_network.private["a"].id
  priority = 110

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = local.cidrs.private_vpn_peers.a.a
    dest_range = local.cidrs.private_vpn_peers.a.b
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.private["a"].ip_address
}

resource "google_network_connectivity_policy_based_route" "privatevpn-ab--aa" {
  name = "${var.name}-privatevpn-ab-to-aa"
  description = "vpns in private-a"
  network = google_compute_network.private["a"].id
  priority = 111

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = local.cidrs.private_vpn_peers.a.b
    dest_range = local.cidrs.private_vpn_peers.a.a
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.private["a"].ip_address
}
