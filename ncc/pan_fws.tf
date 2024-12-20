resource "random_id" "rid" {
  byte_length = 3
}

resource "google_compute_instance" "fwp" {
  for_each     = var.networks["mgmt"]
  name         = "${var.name}-fw-${each.key}-p-${random_id.rid.hex}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available[each.key].names[0]

  can_ip_forward = true
  metadata = merge(
    var.ssh_key_path != "" ? { ssh-keys = "admin:${file(var.ssh_key_path)}" } : {},
    var.bootstrap_options["common"],
    {
      vm-auth-key = panos_vm_auth_key.this.auth_key
      dgname  = panos_device_group.ncc_r[each.key].name
      tplname = panos_panorama_template_stack.fwp[each.key].name
    }
  )


  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-${var.fw_image}"
    }
    auto_delete = true
  }


  network_interface {
    subnetwork = google_compute_subnetwork.internet[each.key].id
    network_ip = local.private_ips.fwp[each.key].eth1_1_ip
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt[each.key].id
    network_ip = local.private_ips.fwp[each.key].mgmt_ip
    access_config {
      // Ephemeral public IP
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.internal[each.key].id
    network_ip = local.private_ips.fwp[each.key].eth1_2_ip
  }
  network_interface {
    subnetwork = google_compute_subnetwork.ha[each.key].id
    network_ip = local.private_ips.fwp[each.key].eth1_3_ip
  }
}

resource "google_compute_instance" "fws" {
  for_each     = var.networks["mgmt"]
  name         = "${var.name}-fw-${each.key}-s-${random_id.rid.hex}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available[each.key].names[1]

  can_ip_forward = true
  metadata = merge(
    var.ssh_key_path != "" ? { ssh-keys = "admin:${file(var.ssh_key_path)}" } : {},
    var.bootstrap_options["common"],
    {
      vm-auth-key = panos_vm_auth_key.this.auth_key
      dgname  = panos_device_group.ncc_r[each.key].name
      tplname = panos_panorama_template_stack.fws[each.key].name
    }
  )


  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-${var.fw_image}"
    }
    auto_delete = true
  }


  network_interface {
    subnetwork = google_compute_subnetwork.internet[each.key].id
    network_ip = local.private_ips.fws[each.key].eth1_1_ip
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt[each.key].id
    network_ip = local.private_ips.fws[each.key].mgmt_ip
    access_config {
      // Ephemeral public IP
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.internal[each.key].id
    network_ip = local.private_ips.fws[each.key].eth1_2_ip
  }
  network_interface {
    subnetwork = google_compute_subnetwork.ha[each.key].id
    network_ip = local.private_ips.fws[each.key].eth1_3_ip
  }
}

resource "google_compute_instance_group" "fwp" {
  for_each = var.networks["mgmt"]
  name     = "${var.name}-fwp-${each.key}"
  instances = [
    google_compute_instance.fwp[each.key].self_link,
  ]
  zone = data.google_compute_zones.available[each.key].names[0]
  named_port {
    name = "s1"
    port = "8081"
  }
  named_port {
    name = "s2"
    port = "8082"
  }
}

resource "google_compute_instance_group" "fws" {
  for_each = var.networks["mgmt"]
  name     = "${var.name}-fws-${each.key}"
  instances = [
    google_compute_instance.fws[each.key].self_link,
  ]
  zone = data.google_compute_zones.available[each.key].names[1]
  named_port {
    name = "s1"
    port = "8081"
  }
  named_port {
    name = "s2"
    port = "8082"
  }
}

# output "fw_mgmt_ip" {
#   value = google_compute_instance.fwp[*].network_interface.1.access_config.0.nat_ip
# }
