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
  check_interval_sec  = 10
  healthy_threshold   = 3
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
    var.bootstrap_options.vm,
    var.payg == false ? var.bootstrap_options.vm_byol : var.bootstrap_options.vm_payg,
    {
      # vm-auth-key = ephemeral.panos_vm_auth_key.this.vm_auth_key
      vm-auth-key = panos_vm_auth_key.this.auth_key
    },
  )
  bootstrap_options_s1 = var.airs ? local.bootstrap_options_airs : local.bootstrap_options_vm
  bootstrap_options = merge(
    local.bootstrap_options_s1,
  )
  source_image = coalesce(
    var.airs ? "projects/paloaltonetworksgcp-public/global/images/${var.fw_image["airs_byol"]}" : null,
    var.payg ? "projects/paloaltonetworksgcp-public/global/images/${var.fw_image["vm_payg"]}" : null,
    "projects/paloaltonetworksgcp-public/global/images/${var.fw_image["vm_byol"]}"
  )

}

resource "google_compute_instance_template" "fw" {
  name_prefix    = var.name
  machine_type   = var.fw_machine_type
  can_ip_forward = true
  metadata       = local.bootstrap_options

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
    email = google_service_account.sa.email
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  disk {
    source_image = local.source_image
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }
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
    name = "geneve"
    port = 6081
  }


  # auto_healing_policies {
  #   health_check      = google_compute_health_check.ah.id
  #   initial_delay_sec = 1600
  # }

  update_policy {
    type           = "PROACTIVE"
    minimal_action = "REPLACE"
    #replacement_method = "RECREATE"   # same name
    replacement_method = "SUBSTITUTE"
    #Invalid value for field 'resource.updatePolicy.maxSurge': '{  "fixed": 1}'.
    #    maxSurge must be equal to 0 when replacement method is set to RECREATE, invalid
    #Fixed updatePolicy.maxSurge for regional managed instance group has to be either 0
    #    or at least equal to the number of zones.
    max_surge_fixed = 3
    # Invalid value for field 'resource.updatePolicy.maxUnavailable.fixed': '1'. 
    # Fixed updatePolicy.maxUnavailable for regional managed instance group has 
    # to be either 0 or at least equal to the number of zones., invalid
    max_unavailable_fixed = 0
  }

  instance_lifecycle_policy {
    force_update_on_repair    = "NO"     # default is NO
    default_action_on_failure = "REPAIR" # default is REPAIR
  }
}



resource "google_compute_region_backend_service" "fw_private" {
  provider              = google-beta
  name                  = "${var.name}-bsvc-fw-prv"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = google_compute_network.private.id
  backend {
    group          = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode = "CONNECTION"
  }
  /*
  backend {
    group = google_compute_region_instance_group_manager.fws2.instance_group
  }
  */
}

resource "google_compute_forwarding_rule" "private" {
  for_each              = toset(data.google_compute_zones.this.names)
  name                  = "${var.name}-private-${each.key}"
  backend_service       = google_compute_region_backend_service.fw_private.id
  load_balancing_scheme = "INTERNAL"
  ports                 = [6081]
  ip_protocol           = "UDP"
  network               = google_compute_network.private.id
  subnetwork            = google_compute_subnetwork.private.id
}



