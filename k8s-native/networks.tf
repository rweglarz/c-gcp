resource "google_compute_network" "k8s" {
  name                    = "${var.name}-k8s"
  auto_create_subnetworks = "false"
}


resource "google_compute_subnetwork" "k8s" {
  name          = "${var.name}-k8s"
  ip_cidr_range = cidrsubnet(var.cidr, 0, 0)
  network       = google_compute_network.k8s.id
}


resource "google_compute_firewall" "mgmt-i" {
  name      = "${var.name}-internet-i"
  network   = google_compute_network.k8s.id
  direction = "INGRESS"
  source_ranges = concat(
    [var.cidr],
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for r in var.gcp_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_router" "k8s" {
  name    = "${var.name}-rtr-k8s"
  network = google_compute_network.k8s.id
}

resource "google_compute_router_nat" "k8s_nat" {
  name   = "${var.name}-rtr-k8s"
  router = google_compute_router.k8s.name

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
