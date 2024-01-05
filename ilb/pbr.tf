resource "google_network_connectivity_policy_based_route" "r1" {
  name = "${var.name}-r1"
  description = "route 1"
  network = google_compute_network.data_nets[1].id
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.fwdrule[1].ip_address

  virtual_machine {
    tags = [
      "workloads-a",
      "workloads-b",
    ]
  }
}
