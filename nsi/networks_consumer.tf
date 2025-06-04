resource "google_compute_network" "client" {
  provider                = google.consumer
  name                    = "${var.name}-client"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "client" {
  provider      = google.consumer
  name          = "${var.name}-client-s"
  ip_cidr_range = local.cidrs.client
  network       = google_compute_network.client.id
}


resource "google_compute_firewall" "consumer-i" {
  provider = google.consumer
  for_each = merge(
    {
      client = google_compute_network.client.id
    },
  )
  name      = "${var.name}-${each.key}-i"
  network   = each.value
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "35.235.240.0/20", # iap
    ],
    [for r in var.mgmt_ips : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
