resource "google_network_security_intercept_endpoint_group" "this" {
  provider                    = google.consumerp
  intercept_endpoint_group_id = "eg"

  location                   = "global"
  intercept_deployment_group = google_network_security_intercept_deployment_group.this.id
}

resource "google_network_security_intercept_endpoint_group_association" "this" {
  provider                                = google.consumer
  intercept_endpoint_group_association_id = "ega"

  location                 = "global"
  network                  = google_compute_network.client.id
  intercept_endpoint_group = google_network_security_intercept_endpoint_group.this.id
}



resource "google_network_security_security_profile" "sp1" {
  provider = google.consumer
  name     = "security-profile-1"

  parent = "organizations/${var.consumer_org}"
  type   = "CUSTOM_INTERCEPT"

  custom_intercept_profile {
    intercept_endpoint_group = google_network_security_intercept_endpoint_group.this.id
  }
}

resource "google_network_security_security_profile_group" "spg1" {
  provider = google.consumer
  name     = "sec-profile-group-1"

  parent                   = "organizations/${var.consumer_org}"
  custom_intercept_profile = google_network_security_security_profile.sp1.id
}



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
  provider = google.consumer
  priority = 100

  firewall_policy = google_compute_firewall_policy.hierarchical.name
  enable_logging  = true
  #   action                 = "allow"
  action                 = "apply_security_profile_group"
  security_profile_group = format("//networksecurity.googleapis.com/%s", google_network_security_security_profile_group.spg1.id)
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
# #endregion



#region   network policies
resource "google_compute_network_firewall_policy" "network" {
  provider = google.consumer
  name     = "network-policy"
}

resource "google_compute_network_firewall_policy_association" "network" {
  provider = google.consumer
  name     = "network"


  attachment_target = google_compute_network.client.id
  firewall_policy   = google_compute_network_firewall_policy.network.id
}

resource "google_compute_network_firewall_policy_rule" "egress_n_1" {
  provider = google.consumer
  priority = 110

  firewall_policy = google_compute_network_firewall_policy.network.network_firewall_policy_id
  enable_logging  = true
  # action                 = "allow"
  action                 = "apply_security_profile_group"
  security_profile_group = format("//networksecurity.googleapis.com/%s", google_network_security_security_profile_group.spg1.id)
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
#endregion
