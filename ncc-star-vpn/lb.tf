resource "google_compute_region_health_check" "fw" {
  for_each = toset(local.regions)

  name   = "${var.name}-r-${each.key}"
  region = each.key

  check_interval_sec  = 20
  timeout_sec         = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = "443"
  }
}

locals {
  all_zones_t = flatten([ for r,rv in data.google_compute_zones.this: rv.names ])
}

resource "google_compute_instance_group" "fw" {
  for_each  = toset(local.all_zones_t)

  name      = "${var.name}-fw-${each.key}"
  instances = [ for k,v in google_compute_instance.fw: v.self_link if v.zone==each.key ]
  zone = each.key
}


resource "google_compute_region_backend_service" "fw" {
  for_each = toset(local.regions)

  provider              = google-beta
  name                  = "${var.name}-fw-${each.key}"
  region                = each.key
  # protocol              = "UNSPECIFIED"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw[each.key].id]
  session_affinity      = "CLIENT_IP"
  network               = google_compute_network.fw.id
  dynamic "backend" {
    for_each = toset(data.google_compute_zones.this[each.key].names)
    content {
      group          = google_compute_instance_group.fw[backend.key].self_link
      balancing_mode = "CONNECTION"
    }
  }
}

resource "google_compute_forwarding_rule" "fw" {
  for_each = google_compute_subnetwork.fw

  name                  = "${var.name}-fw-${each.key}"
  region                = each.value.region
  backend_service       = google_compute_region_backend_service.fw[each.value.region].id
  load_balancing_scheme = "INTERNAL"
  ports                 = ["80"]
#   all_ports = true
#   ip_protocol = "L3_DEFAULT"
  ip_protocol = "TCP"
  network               = google_compute_network.fw.id
  subnetwork            = each.value.id
  ip_address            = cidrhost(each.value.ip_cidr_range, 2)
  allow_global_access   = true
}
