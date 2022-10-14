locals {
  data_nets = [
    google_compute_network.internet,
    google_compute_network.internal,
  ]
  data_subnets = [
    google_compute_subnetwork.internet,
    google_compute_subnetwork.internal,
  ]
}
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

resource "google_compute_region_backend_service" "bsvc" {
  provider              = google-beta
  count                 = 2
  name                  = "${var.name}-bsvc-${count.index}"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = local.data_nets[count.index].id
  backend {
    group = google_compute_instance_group.fws.id
  }
  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "fwdrule" {
  count                 = 2
  name                  = "${var.name}-fwdrule-${count.index}"
  backend_service       = google_compute_region_backend_service.bsvc[count.index].id
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network               = local.data_nets[count.index].id
  subnetwork            = local.data_subnets[count.index].id
  ip_address            = cidrhost(local.data_subnets[count.index].ip_cidr_range, 2)
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
