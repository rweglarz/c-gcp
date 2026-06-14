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
  bootstrap_options = merge(
    var.bootstrap_options.common,
    var.bootstrap_options.vm,
    var.payg == false ? var.bootstrap_options.vm_byol : var.bootstrap_options.vm_payg,
    {
      vm-auth-key = panos_vm_auth_key.this.auth_key
    },
  )
  source_image = coalesce(
    var.payg ? var.fw_images["vm_payg"] : null,
    var.fw_images["default"]
  )

  # Map of internal trust-side networks requiring Internal Load Balancing
  trust_networks = {
    private = {
      network = google_compute_network.private.id
      subnet  = google_compute_subnetwork.private.id
      cidr    = google_compute_subnetwork.private.ip_cidr_range
    }
    vpn = {
      network = google_compute_network.vpn.id
      subnet  = google_compute_subnetwork.vpn.id
      cidr    = google_compute_subnetwork.vpn.ip_cidr_range
    }
  }
}

resource "google_compute_instance_template" "fw" {
  name_prefix    = var.name
  machine_type   = var.fw_machine_type
  can_ip_forward = true
  metadata       = local.bootstrap_options

  service_account {
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.self_link
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpn.self_link
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.self_link
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
  labels = var.labels

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

  update_policy {
    type                  = "OPPORTUNISTIC"
    minimal_action        = "REFRESH"
    replacement_method    = "SUBSTITUTE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 3
  }

  instance_lifecycle_policy {
    force_update_on_repair    = "NO"
    default_action_on_failure = "REPAIR"
  }
}

resource "google_compute_region_backend_service" "fws" {
  for_each = local.trust_networks

  provider              = google-beta
  name                  = "${var.name}-bsvc-fws-${each.key}"
  protocol              = "UNSPECIFIED"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = each.value.network
  backend {
    group          = google_compute_region_instance_group_manager.fws.instance_group
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "private" {
  for_each = local.trust_networks

  name                  = "${var.name}-fwdrule-${each.key}"
  backend_service       = google_compute_region_backend_service.fws[each.key].id
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  ip_protocol           = "TCP"
  network               = each.value.network
  subnetwork            = each.value.subnet
  ip_address            = cidrhost(each.value.cidr, 5) # Reservs .5 as default ILB gateway
}

#region Static Routing
# For Private VPC: Send all traffic (0.0.0.0/0) through the private ILB
resource "google_compute_route" "private_dg" {
  name         = "${var.name}-dg-private"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.private.id
  next_hop_ilb = google_compute_forwarding_rule.private["private"].self_link
  priority     = 10
}

# For VPN VPC: Send only RFC1918 ranges through the vpn ILB, internet (0.0.0.0/0) goes direct
resource "google_compute_route" "vpn_rfc1918" {
  for_each     = toset(["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"])
  name         = "${var.name}-rfc1918-${replace(replace(each.key, "/", "-"), ".", "-")}-vpn"
  dest_range   = each.key
  network      = google_compute_network.vpn.id
  next_hop_ilb = google_compute_forwarding_rule.private["vpn"].self_link
  priority     = 10
}
#endregion
