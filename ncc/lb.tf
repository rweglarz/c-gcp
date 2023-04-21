resource "google_compute_health_check" "s" {
  for_each            = var.global_services
  name                = "${var.name}-s-${each.key}"
  check_interval_sec  = 5
  timeout_sec         = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = each.value
  }
}

resource "google_compute_backend_service" "ext" {
  for_each              = var.global_services
  name                  = "${var.name}-ext-${each.key}"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.s[each.key].id]
  session_affinity      = "CLIENT_IP"
  backend {
    group                        = google_compute_instance_group.fwp["europe-west1"].id
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 10000
  }
  backend {
    group                        = google_compute_instance_group.fwp["europe-west2"].id
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 10000
  }
  backend {
    group                        = google_compute_instance_group.fws["europe-west1"].id
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 10000
  }
  backend {
    group                        = google_compute_instance_group.fws["europe-west2"].id
    balancing_mode               = "CONNECTION"
    max_connections_per_instance = 10000
  }
  port_name = each.key
}

resource "google_compute_target_tcp_proxy" "ext" {
  #  provider = google-beta
  for_each        = var.global_services
  name            = "${var.name}-ext-${each.key}"
  backend_service = google_compute_backend_service.ext[each.key].id
}


resource "google_compute_global_forwarding_rule" "ext" {
  for_each              = var.global_services
  name                  = "${var.name}-ext-${each.key}"
  provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_tcp_proxy.ext[each.key].id
  #  ip_address            = google_compute_global_address.default.id
}



resource "google_compute_region_health_check" "fw" {
  for_each            = var.networks["internet"]
  name                = "${var.name}-rhealthcheck-${each.key}"
  region              = each.key
  check_interval_sec  = 5
  timeout_sec         = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = "54321"
  }
}

resource "google_compute_region_backend_service" "ext" {
  for_each              = var.networks["internet"]
  provider              = google-beta
  name                  = "${var.name}-ext-${each.key}"
  region                = each.key
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.fw[each.key].id]
  session_affinity      = "CLIENT_IP"
  backend {
    group          = google_compute_instance_group.fwp[each.key].id
    balancing_mode = "CONNECTION"
  }
  backend {
    group          = google_compute_instance_group.fws[each.key].id
    balancing_mode = "CONNECTION"
  }

  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "ext" {
  for_each              = var.networks["internet"]
  name                  = "${var.name}-ext-${each.key}"
  region                = each.key
  backend_service       = google_compute_region_backend_service.ext[each.key].id
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
}
