resource "google_compute_instance" "tc" {
  count = var.airs ? 1 : 0

  name         = "${var.name}-airs-tc-${random_id.this.hex}"
  machine_type = "n2-standard-2"

  can_ip_forward = false
  metadata = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["airs_tc"],
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
      image = var.fw_images["airs_fw"]
    }
    auto_delete = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    network_ip = cidrhost(google_compute_subnetwork.mgmt.ip_cidr_range, 99)
  }
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}

