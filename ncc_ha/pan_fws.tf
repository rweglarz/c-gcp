resource "random_id" "server" {
  byte_length = 3
}

resource "google_compute_instance" "fw" {
  count        = 2
  name         = "${var.name}-fw${count.index}-${random_id.server.hex}"
  machine_type = var.machine_type
  zone         = var.zones[count.index]

  can_ip_forward = true
  metadata = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["fw_${count.index}"],
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
      image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-flex-byol-1017"
    }
    auto_delete = true
  }


  network_interface {
    subnetwork = google_compute_subnetwork.internet.id
    network_ip = cidrhost(google_compute_subnetwork.internet.ip_cidr_range, 5 + count.index)
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    network_ip = cidrhost(google_compute_subnetwork.mgmt.ip_cidr_range, 5 + count.index)
    access_config {
      // Ephemeral public IP
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.internal.id
    network_ip = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 5 + count.index)
  }
  network_interface {
    subnetwork = google_compute_subnetwork.ha.id
    network_ip = cidrhost(google_compute_subnetwork.ha.ip_cidr_range, 5 + count.index)
  }

}

resource "google_compute_instance_group" "fws" {
  count     = 2
  name      = "${var.name}-fw${count.index}-ig"
  instances = [google_compute_instance.fw[count.index].self_link]
  zone      = var.zones[count.index]
}


output "fw_mgmt_ip" {
  value = [
    google_compute_instance.fw[0].network_interface.1.access_config.0.nat_ip,
    google_compute_instance.fw[1].network_interface.1.access_config.0.nat_ip,
  ]
}
