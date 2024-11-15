resource "google_network_connectivity_policy_based_route" "a" {
  name = "${var.name}-private-a"
  description = "workloads in private-a"
  network = google_compute_network.private["a"].id
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.private["a"].ip_address

  virtual_machine {
    tags = [
      "workloads-pbr",
    ]
  }
}
