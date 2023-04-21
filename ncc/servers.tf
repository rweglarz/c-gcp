data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "srv_app0" {
  for_each     = var.networks["srv_app0"]
  name         = "${var.name}-srv-app0-${each.key}"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[each.key].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv_app0[each.key].id
    network_ip = cidrhost(google_compute_subnetwork.srv_app0[each.key].ip_cidr_range, 9)
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "srv_app1" {
  for_each     = var.networks["srv_app1"]
  name         = "${var.name}-srv-app1-${each.key}"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[each.key].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.srv_app1[each.key].id
    network_ip = cidrhost(google_compute_subnetwork.srv_app1[each.key].ip_cidr_range, 9)
    access_config {
      // Ephemeral public IP
    }
  }
}


resource "google_compute_instance" "srv_ext" {
  for_each     = var.networks["internet"]
  name         = "${var.name}-srv-ext-${each.key}"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[each.key].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.internet[each.key].id
    network_ip = cidrhost(google_compute_subnetwork.internet[each.key].ip_cidr_range, 9)
    access_config {
      // Ephemeral public IP
    }
  }
}
