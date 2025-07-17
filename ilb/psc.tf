resource "google_compute_subnetwork" "psc_nat" {
  for_each = local.cidrs.psc_nat
  name          = "${var.name}-psc-nat-${each.key}-s"
  ip_cidr_range = local.cidrs.psc_nat[each.key]
  network       = google_compute_network.private[each.key].id
  purpose       =  "PRIVATE_SERVICE_CONNECT"
}



resource "google_compute_forwarding_rule" "airs_udp" {
  for_each = google_compute_network.private
  name                  = "${var.name}-fwdrule-airs-udp-${each.key}"
  backend_service       = google_compute_region_backend_service.fws[each.key].id
  load_balancing_scheme = "INTERNAL"
  ports                 = ["6080"]
  ip_protocol           = "UDP"
  network               = google_compute_network.private[each.key].id
  subnetwork            = google_compute_subnetwork.private[each.key].id
  ip_address            = cidrhost(google_compute_subnetwork.private[each.key].ip_cidr_range, 4)
  allow_global_access = true
}


resource "google_compute_service_attachment" "this" {
  name                  = "${var.name}-psc-a"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  reconcile_connections = true
  enable_proxy_protocol = false
  target_service        = google_compute_forwarding_rule.airs_udp["a"].id
  nat_subnets           = [
    google_compute_subnetwork.psc_nat["a"].id
  ]
}

output "psc" {
  value = google_compute_service_attachment.this.id
}
