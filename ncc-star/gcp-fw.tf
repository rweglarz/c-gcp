resource "google_compute_firewall" "this-i" {
  for_each = merge(
    {
      center = google_compute_network.center.id,
      fw     = google_compute_network.fw.id,
    },
    { for k,v in google_compute_network.spoke: k => v.id },
  )
  name      = "${each.key}-i"
  network   = each.value
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "35.235.240.0/20", # iap
      "130.211.0.0/22",  # hc
      "35.191.0.0/16",   # hc 
    ],
    [for r in var.mgmt_ips : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
