resource "google_compute_region_health_check" "fw" {
  name                = "${var.name}-rhealthcheck"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 3
  unhealthy_threshold = 3

  tcp_health_check {
    port = "443"
  }
}

resource "google_compute_region_backend_service" "internal" {
  provider              = google-beta
  name                  = "${var.name}-internal"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = google_compute_network.internal.id
  backend {
    group = google_compute_instance_group.fws.id
  }
  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "internal" {
  name                  = "${var.name}-internal"
  backend_service       = google_compute_region_backend_service.internal.id
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network               = google_compute_network.internal.id
  subnetwork            = google_compute_subnetwork.internal.id
  ip_address            = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 2)
}



resource "google_compute_region_backend_service" "ext" {
  provider              = google-beta
  name                  = "${var.name}-ext"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  backend {
    group = google_compute_instance_group.fws.id
  }
  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "ext" {
  name                  = "${var.name}-ext"
  backend_service       = google_compute_region_backend_service.ext.id
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
}
resource "google_compute_forwarding_rule" "ext-a" {
  count = 2
  name  = "${var.name}-ext-a-${count.index}"

  backend_service       = google_compute_region_backend_service.ext.id
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
}

output "ext_lb_ip" {
  value = [
    google_compute_forwarding_rule.ext.ip_address,
  ]
}
output "ext_add" {
  value = google_compute_forwarding_rule.ext-a[*].ip_address
}
