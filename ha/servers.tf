data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "srv0" {
  name         = "${var.name}-srv0"
  machine_type = "f1-micro"
  zone         = var.zones[0]

  metadata = merge(
    var.ssh_key_path != "" ? { ssh-keys = "ubuntu:${file(var.ssh_key_path)}" } : {},
  )

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv0-s0.id
    network_ip = cidrhost(google_compute_subnetwork.srv0-s0.ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "srv1" {
  name         = "${var.name}-srv-1"
  machine_type = "f1-micro"
  zone         = var.zones[1]

  metadata = merge(
    var.ssh_key_path != "" ? { ssh-keys = "ubuntu:${file(var.ssh_key_path)}" } : {},
  )

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv1-s0.id
    network_ip = cidrhost(google_compute_subnetwork.srv1-s0.ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}
