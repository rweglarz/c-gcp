resource "google_compute_firewall" "inbound-mgmt-private" {
  for_each = {
    internet = google_compute_network.internet.id
    internal = google_compute_network.internal.id
    mgmt     = google_compute_network.mgmt.id
    srv-app0 = google_compute_network.srv_app0.id
    srv-app1 = google_compute_network.srv_app1.id
    test1    = google_compute_network.test1.id
    test2    = google_compute_network.test2.id
  }
  name      = "${var.name}-${each.key}-i"
  network   = each.value
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : r.cidr],
    [for r in var.gcp_ips  : r.cidr],
    [for r in var.tmp_ips  : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
