resource "google_network_connectivity_policy_based_route" "a-fw" {
  name = "${var.name}-fw-direct-return"
  description = "firewalls"
  network = google_compute_network.fw.id
  priority = 1

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
  }
  next_hop_other_routes = "DEFAULT_ROUTING"

  virtual_machine {
    tags = [
      "firewall"
    ]
  }
}

resource "google_network_connectivity_policy_based_route" "rest" {
  name = "${var.name}-rest"
  description = "workloads"
  network = google_compute_network.fw.id
  priority = 100

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "172.16.0.0/12"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.fw["s1"].ip_address
}

resource "google_network_connectivity_policy_based_route" "rest-dg" {
  name = "${var.name}-rest-dg"
  description = "workloads"
  network = google_compute_network.fw.id
  priority = 1000

  filter {
    protocol_version = "IPV4"
    ip_protocol = "ALL"
    src_range = "172.16.0.0/12"
    dest_range = "0.0.0.0/0"
  }
  next_hop_ilb_ip = google_compute_forwarding_rule.fw["s1"].ip_address
}
