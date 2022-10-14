data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "server1" {
  name         = "${var.name}-srv-1"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.internet.id
    network_ip = cidrhost(google_compute_subnetwork.internet.ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "server2" {
  name         = "${var.name}-srv-2"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.internal.id
    network_ip = cidrhost(google_compute_subnetwork.internal.ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}
