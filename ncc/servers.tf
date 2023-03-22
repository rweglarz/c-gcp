data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "srv0" {
  for_each     = var.networks["srv0"]
  name         = "${var.name}-srv0-${each.key}"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[each.key].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv0[each.key].id
    network_ip = cidrhost(google_compute_subnetwork.srv0[each.key].ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "srv1" {
  for_each     = var.networks["srv0"]
  name         = "${var.name}-srv1-${each.key}"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[each.key].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv1[each.key].id
    network_ip = cidrhost(google_compute_subnetwork.srv1[each.key].ip_cidr_range, 8)
    access_config {
      // Ephemeral public IP
    }
  }
}
