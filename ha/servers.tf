data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "srv" {
  for_each = {
    srv0 = {
      zone = var.zones[0]
      subnetwork = google_compute_subnetwork.srv0-s0
    }
    srv1 = {
      zone = var.zones[1]
      subnetwork = google_compute_subnetwork.srv1-s0
    }
  }
  name         = "${var.name}-${each.key}"
  machine_type = var.srv_type
  zone         = each.value.zone

  metadata = merge(
    var.ssh_key_path != "" ? { ssh-keys = "ubuntu:${file(var.ssh_key_path)}" } : {},
  )

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = each.value.subnetwork.self_link
    network_ip = cidrhost(each.value.subnetwork.ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}
