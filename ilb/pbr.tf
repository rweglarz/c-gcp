resource "google_network_connectivity_policy_based_route" "n2" {
  name = "${var.name}-n2"
  description = "workloads in n2"
  network = google_compute_network.data_nets[0].id
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.fwdrule[0].ip_address

  virtual_machine {
    tags = [
      "workloads-a",
      "workloads-b",
    ]
  }
}

resource "google_network_connectivity_policy_based_route" "n2-exc-c" {
  name = "${var.name}-n2-exception-to-c"
  description = "workloads in n2 exc"
  network = google_compute_network.data_nets[0].id
  priority = 90

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.2.80"
    dest_range = "172.16.2.82"
  }
  next_hop_other_routes = "DEFAULT_ROUTING"

  virtual_machine {
    tags = [
      "workloads-a",
    ]
  }
}
