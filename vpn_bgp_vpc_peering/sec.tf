resource "google_compute_firewall" "network11" {
  name      = "network11-inbound"
  network   = google_compute_network.network11.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    ["10.0.0.0/8"],
    ["192.168.0.0/16"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "network1" {
  name      = "network1-inbound"
  network   = google_compute_network.network1.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    ["10.0.0.0/8"],
    ["192.168.0.0/16"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_firewall" "network2" {
  name      = "network2-inbound"
  network   = google_compute_network.network2.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    ["10.0.0.0/8"],
    ["192.168.0.0/16"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_firewall" "network3" {
  name      = "network3-inbound"
  network   = google_compute_network.network3.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    ["10.0.0.0/8"],
    ["192.168.0.0/16"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}





