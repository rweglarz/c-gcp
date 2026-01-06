#region intercept
resource "google_network_security_intercept_endpoint_group" "this" {
  provider = google.consumerp

  location = "global"

  intercept_endpoint_group_id = "eg-in-band"
  intercept_deployment_group  = google_network_security_intercept_deployment_group.this.id
}

resource "google_network_security_intercept_endpoint_group_association" "this" {
  for_each = google_compute_network.client
  provider = google.consumer

  location = "global"
  network  = each.value.id

  intercept_endpoint_group                = google_network_security_intercept_endpoint_group.this.id
  intercept_endpoint_group_association_id = "ega-${each.key}"
}


resource "google_network_security_security_profile" "spi" {
  provider = google.consumer
  name     = "sec-profile-intercept"

  parent = "organizations/${var.consumer_org}"
  type   = "CUSTOM_INTERCEPT"

  custom_intercept_profile {
    intercept_endpoint_group = google_network_security_intercept_endpoint_group.this.id
  }
}

resource "google_network_security_security_profile_group" "spgi" {
  provider = google.consumer
  name     = "sec-profile-group-intercept"

  parent                   = "organizations/${var.consumer_org}"
  custom_intercept_profile = google_network_security_security_profile.spi.id
}
#endregion



#region mirror
resource "google_network_security_mirroring_endpoint_group" "this" {
  provider = google.consumerp

  location = "global"

  mirroring_endpoint_group_id = "eg-out-of-band"
  mirroring_deployment_group  = google_network_security_mirroring_deployment_group.this.id
}

resource "google_network_security_mirroring_endpoint_group_association" "this" {
  for_each = google_compute_network.client
  provider = google.consumer

  location = "global"
  network  = each.value.id

  mirroring_endpoint_group                = google_network_security_mirroring_endpoint_group.this.id
  mirroring_endpoint_group_association_id = "ega-${each.key}"
}


resource "google_network_security_security_profile" "spm" {
  provider = google.consumer
  name     = "sec-profile-mirror"

  parent = "organizations/${var.consumer_org}"
  type   = "CUSTOM_MIRRORING"

  custom_mirroring_profile {
    mirroring_endpoint_group = google_network_security_mirroring_endpoint_group.this.id
  }
}

resource "google_network_security_security_profile_group" "spgm" {
  provider = google.consumer
  name     = "sec-profile-group-mirror"

  parent                   = "organizations/${var.consumer_org}"
  custom_mirroring_profile = google_network_security_security_profile.spm.id
  depends_on = [
    google_network_security_security_profile.spm
  ]
}
#endregion



#region   hierarchical policies
resource "google_compute_firewall_policy" "hierarchical" {
  provider   = google.consumer
  short_name = "hierarchical-policy-folder"

  # parent      = "organizations/${var.consumer_org}"
  parent = "folders/${var.consumer_folder}" # nsi
}

resource "google_compute_firewall_policy_association" "hierarchical" {
  provider = google.consumer
  name     = "hierarchical-folder"

  firewall_policy   = google_compute_firewall_policy.hierarchical.id
  attachment_target = "folders/${var.consumer_folder}" # nsi
}

resource "google_compute_firewall_policy_rule" "egress_h_1" {
  provider = google-beta.consumer
  priority = 101

  firewall_policy = google_compute_firewall_policy.hierarchical.name
  enable_logging  = true
  #   action                 = "allow"
  action                 = "apply_security_profile_group"
  security_profile_group = format("//networksecurity.googleapis.com/%s", google_network_security_security_profile_group.spgi.id)
  direction              = "EGRESS"
  disabled               = false

  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    dest_fqdns     = []
    # dest_region_codes         = ["US"]
    # dest_threat_intelligences = ["iplist-known-malicious-ips"]
    src_address_groups  = []
    dest_address_groups = []
    dest_network_scope = "INTERNET"

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80, 443]
    }

    layer4_configs {
      ip_protocol = "udp"
      ports       = [53]
    }
  }
}
# #endregion


#region   network policies
resource "google_compute_network_firewall_policy" "network" {
  provider = google.consumer
  name     = "network-policy"
}

resource "google_compute_network_firewall_policy_association" "network" {
  for_each = google_compute_network.client
  provider = google.consumer

  name              = "network-${each.key}"
  attachment_target = each.value.id
  firewall_policy   = google_compute_network_firewall_policy.network.id
}

resource "google_compute_network_firewall_policy_rule" "egress_n_1" {
  provider = google.consumer
  priority = 101

  firewall_policy = google_compute_network_firewall_policy.network.network_firewall_policy_id
  enable_logging  = true
  # action                 = "allow"
  action                 = "apply_security_profile_group"
  security_profile_group = format("//networksecurity.googleapis.com/%s", google_network_security_security_profile_group.spgi.id)
  direction              = "EGRESS"
  disabled               = false

  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    dest_fqdns     = []
    # dest_region_codes         = ["US"]
    # dest_threat_intelligences = ["iplist-known-malicious-ips"]
    src_address_groups  = []
    dest_address_groups = []

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80, 443]
    }

    layer4_configs {
      ip_protocol = "udp"
      ports       = [53]
    }
  }
}

resource "google_compute_network_firewall_policy_packet_mirroring_rule" "mirror_n_1" {
  provider = google-beta.consumer
  priority = 300

  firewall_policy        = google_compute_network_firewall_policy.network.network_firewall_policy_id
  action                 = "mirror"
  security_profile_group = format("//networksecurity.googleapis.com/%s", google_network_security_security_profile_group.spgm.id)
  direction              = "INGRESS"
  disabled               = false

  match {
    src_ip_ranges = ["172.16.0.0/12"]
    # dest_region_codes         = ["US"]
    # dest_threat_intelligences = ["iplist-known-malicious-ips"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80, 443]
    }
  }
}
#endregion
