resource "google_compute_health_check" "ah" {
  name                = "${var.name}-g-auto-heal-php-login"
  check_interval_sec  = 300
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/php/login.php"
    port         = "54321"
  }
}
resource "google_compute_region_health_check" "fw" {
  name                = "${var.name}-r-healthcheck"
  check_interval_sec  = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2
  timeout_sec         = 1

  http_health_check {
    request_path = "/unauth/php/health.php"
    port         = "54321"
  }
}

locals {
  bootstrap_options_airs = merge(
    var.bootstrap_options.common,
    var.bootstrap_options.airs,

  )
  bootstrap_options_vm = merge(
    var.bootstrap_options.common,
    var.payg==false ? var.bootstrap_options.vm_byol : var.bootstrap_options.vm_payg,
    {
      vm-auth-key = panos_vm_auth_key.this.auth_key
    },
  )
  bootstrap_options_s1 = var.airs ? local.bootstrap_options_airs : local.bootstrap_options_vm
  bootstrap_options = merge(
    local.bootstrap_options_s1,
    var.session_resiliency ? {
      "plugin-op-commands" = try(join(",", [local.bootstrap_options_s1["plugin-op-commands"], "set-sess-ress:True"]), "set-sess-ress:True"),
      "redis-endpoint"     = "${google_redis_instance.this[0].host}:${google_redis_instance.this[0].port}",
    } : {},
    var.session_resiliency && var.session_resiliency_auth ? {
      "redis-auth"         = google_redis_instance.this[0].auth_string,
    } : {},
  )
  source_image = coalesce(
    var.airs ? "projects/paloaltonetworksgcp-public/global/images/ai-runtime-security-byol-1125h1" : null,
    var.payg ? "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-bundle2-1126" : null,
    "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-byol-1126"
  )

}

resource "google_compute_instance_template" "fw" {
  name_prefix    = var.name
  machine_type   = var.fw_machine_type
  can_ip_forward = true
  metadata       = local.bootstrap_options

  /*
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }
  */
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
  }
  dynamic "network_interface" {
    for_each = google_compute_subnetwork.private
    content {
      subnetwork = network_interface.value.id
    }
  }

  disk {
    source_image = local.source_image
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }
  tags = [
    "firewalls"
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "fws" {
  name               = "${var.name}-igm"
  base_instance_name = "${var.name}-igm"

  version {
    instance_template = google_compute_instance_template.fw.id
  }

  target_size = var.fw_count

  named_port {
    name = "https"
    port = 443
  }
  named_port {
    name = "p81"
    port = 81
  }
  named_port {
    name = "p82"
    port = 82
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.ah.id
    initial_delay_sec = 1600
  }

  update_policy {
    type               = "OPPORTUNISTIC"
    minimal_action     = "REPLACE"    # same name
    replacement_method = "RECREATE"   # new name
    #replacement_method = "SUBSTITUTE"
    #Invalid value for field 'resource.updatePolicy.maxSurge': '{  "fixed": 1}'. 
    #    maxSurge must be equal to 0 when replacement method is set to RECREATE, invalid
    #Fixed updatePolicy.maxSurge for regional managed instance group has to be either 0 
    #    or at least equal to the number of zones.
    max_surge_fixed = 0
    max_unavailable_fixed = 3
  }
}



resource "google_compute_region_backend_service" "fws" {
  for_each = google_compute_network.private

  provider              = google-beta
  name                  = "${var.name}-bsvc-fws-${each.key}"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = each.value.id
  backend {
    group          = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode = "CONNECTION"
  }
  /*
  backend {
    group = google_compute_region_instance_group_manager.fws2.instance_group
  }
  */
  dynamic "connection_tracking_policy" {
    for_each = var.session_resiliency ? [1] : [0]
    content {
      tracking_mode                                = "PER_SESSION"
      connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
    }
  }
}

resource "google_compute_forwarding_rule" "private" {
  for_each = google_compute_network.private
  name                  = "${var.name}-fwdrule-${each.key}"
  backend_service       = google_compute_region_backend_service.fws[each.key].id
  load_balancing_scheme = "INTERNAL"
  #ports                 = ["80"]
  all_ports = true
  # ip_protocol = "L3_DEFAULT"
  ip_protocol = "TCP"
  network               = google_compute_network.private[each.key].id
  subnetwork            = google_compute_subnetwork.private[each.key].id
  ip_address            = cidrhost(google_compute_subnetwork.private[each.key].ip_cidr_range, 5)
}



resource "google_compute_region_backend_service" "public" {
  provider              = google-beta
  name                  = "${var.name}-public"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  backend {
    group          = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode = "CONNECTION"
  }
  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    # connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "public" {
  name                  = "${var.name}-public"
  backend_service       = google_compute_region_backend_service.public.id
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
}



resource "google_compute_route" "private_dg" {
  for_each = google_compute_network.private
  name         = "${var.name}-dg-${each.key}"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.private[each.key].id
  next_hop_ilb = google_compute_forwarding_rule.private[each.key].self_link
  priority     = 10
}

resource "google_compute_route" "private_172" {
  for_each = google_compute_network.private
  name         = "${var.name}-172-${each.key}"
  dest_range   = "172.16.0.0/12"
  network      = google_compute_network.private[each.key].id
  next_hop_ilb = google_compute_forwarding_rule.private[each.key].self_link
  priority     = 10
}
