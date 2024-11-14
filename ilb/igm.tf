resource "google_compute_health_check" "ah" {
  name                = "${var.name}-g-auto-heal-php-login"
  check_interval_sec  = 240
  timeout_sec         = 5
  healthy_threshold   = 6
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/php/login.php"
    port         = "80"
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
    port         = "80"
  }
}

resource "google_compute_instance_template" "fw" {
  name_prefix    = var.name
  machine_type   = var.fw_machine_type
  can_ip_forward = true
  metadata       = merge(
    {
      vm-auth-key = panos_vm_auth_key.this.auth_key
    },
    var.bootstrap_options_byol,
    var.session_resiliency ? {
      "plugin-op-commands" = try(join(",", [var.bootstrap_options_byol["plugin-op-commands"], "set-sess-ress:True"]), "set-sess-ress:True"),
      "redis-endpoint"     = "${google_redis_instance.this[0].host}:${google_redis_instance.this[0].port}",
    } : {},
    var.session_resiliency && var.session_resiliency_auth ? {
      "redis-auth"         = google_redis_instance.this[0].auth_string,
    } : {},
  )

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
    subnetwork = google_compute_subnetwork.public.self_link
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.self_link
  }
  dynamic "network_interface" {
    for_each = google_compute_subnetwork.data_subnet_fw
    content {
      subnetwork = network_interface.value.self_link
    }
  }

  disk {
    source_image = "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-byol-1114"
    #source_image = "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-bundle1-1110"
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



resource "google_compute_region_backend_service" "bsvc" {
  provider              = google-beta
  count                 = var.vpc_count
  name                  = "${var.name}-bsvc-${count.index}"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = google_compute_network.data_nets[count.index].id
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

resource "google_compute_forwarding_rule" "fwdrule" {
  count                 = var.vpc_count
  name                  = "${var.name}-fwdrule-${count.index}"
  backend_service       = google_compute_region_backend_service.bsvc[count.index].id
  load_balancing_scheme = "INTERNAL"
  #ports                 = ["80"]
  all_ports = true
  # ip_protocol = "L3_DEFAULT"
  ip_protocol = "TCP"
  network               = google_compute_network.data_nets[count.index].id
  subnetwork            = google_compute_subnetwork.data_subnet_fw[count.index].id
  ip_address            = cidrhost(google_compute_subnetwork.data_subnet_fw[count.index].ip_cidr_range, 60)
}


resource "google_compute_route" "route" {
  count        = var.vpc_count
  name         = "${var.name}-dg-${count.index}"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.data_nets[count.index].id
  next_hop_ilb = google_compute_forwarding_rule.fwdrule[count.index].ip_address
  #next_hop_ilb = google_compute_forwarding_rule.fwdrule[count.index].self_link
  priority     = 10
  # tags = [
  #   "workloads"
  # ]
}
