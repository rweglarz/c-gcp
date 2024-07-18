resource "google_compute_health_check" "galb" {
  for_each = toset(["81", "82"])
  name                = "${var.name}-galb-${each.key}"
  check_interval_sec  = 20
  timeout_sec         = 2
  healthy_threshold   = 1
  unhealthy_threshold = 3

  http_health_check {
    request_path = "/txt"
    port         = tonumber(each.key)
  }
}

resource "google_compute_global_address" "galb" {
  name     = "galb"
}

resource "google_compute_global_forwarding_rule" "galb" {
  name                  = "${var.name}-galb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.galb.id
  ip_address            = google_compute_global_address.galb.id
}

resource "google_compute_target_http_proxy" "galb" {
  name     = "${var.name}-fw"
  url_map  = google_compute_url_map.galb.id
}


resource "google_compute_url_map" "galb" {
  name     = "${var.name}-fw"
  default_service = google_compute_backend_service.galb-p81.id

  host_rule {
    hosts = [
        "ilb-galb-app2.${trimsuffix(data.google_dns_managed_zone.this.dns_name, ".")}",
    ]
    path_matcher = "app2"
  }
  path_matcher {
    name            = "app2"
    default_service = google_compute_backend_service.galb-p82.id
  }
}

resource "google_compute_backend_service" "galb-p81" {
  name                    = "${var.name}-p81"
  protocol                = "HTTP"
  port_name               = "p81"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 10
  enable_cdn              = false
  custom_request_headers  = [
    "X-Client-Geo-Location: {client_region_subdivision}, {client_city}",
    "X-Forwarded-For: {client_ip_address}",
  ]
  health_checks = [google_compute_health_check.galb["81"].id]
  backend {
    group                 = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 1000
  }
  depends_on = [
    google_compute_region_instance_group_manager.fws
  ]
}

resource "google_compute_backend_service" "galb-p82" {
  name                    = "${var.name}-p82"
  protocol                = "HTTP"
  port_name               = "p82"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 10
  enable_cdn              = false
  custom_request_headers  = [
    "X-Client-Geo-Location: {client_region_subdivision}, {client_city}",
    "X-Forwarded-For: {client_ip_address}",
  ]
  health_checks = [google_compute_health_check.galb["82"].id]
  backend {
    group                 = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 1000
  }
  depends_on = [
    google_compute_region_instance_group_manager.fws
  ]
}

output "alb_address" {
  value = { for k,v in google_dns_record_set.galb: k => v.name }
}
