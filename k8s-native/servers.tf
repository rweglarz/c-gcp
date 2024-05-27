data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}


resource "google_compute_instance" "jumphost" {
  name         = "${var.name}-jumphost"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s.id
    network_ip = cidrhost(google_compute_subnetwork.k8s.ip_cidr_range, 3)
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_address" "cp" {
  name         = "${var.name}-cp"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_instance" "cp" {
  name         = "${var.name}-cp"
  machine_type = "n2-standard-8"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s.id
    network_ip = cidrhost(google_compute_subnetwork.k8s.ip_cidr_range, 4)
    access_config {
      nat_ip = google_compute_address.cp.address
    }
  }
}

resource "google_compute_disk" "worker" {
  for_each = var.nodes.workers
  name     = "longhorn-${each.key}"
  size     = 300
}

resource "google_compute_instance" "worker" {
  for_each     = var.nodes.workers
  name         = "${var.name}-worker-${each.key}"
  machine_type = "n2-standard-8"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 80
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s.id
  }

  attached_disk {
    device_name = "longhorn"
    source      = google_compute_disk.worker[each.key].id
  }

  depends_on = [
    google_compute_instance.jumphost,
    google_compute_instance.cp
  ]
}
