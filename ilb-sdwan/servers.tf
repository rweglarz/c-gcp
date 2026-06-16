resource "google_compute_address" "jumphost" {
  name    = "${var.name}-jumphost"
}

resource "google_compute_instance" "jumphost" {
  name    = "${var.name}-jumphost"
  machine_type = "f1-micro"
  zone         = var.zone
  # service_account {
  #     email  = google_service_account.saj.email
  #     scopes = ["cloud-platform"]
  # }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    access_config {
      nat_ip = google_compute_address.jumphost.address
    }
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}

resource "google_compute_instance" "servers" {
  for_each = {
    workload-a = google_compute_subnetwork.workload["workload-a"].id
    workload-b = google_compute_subnetwork.workload["workload-b"].id
    remote     = google_compute_subnetwork.remote.id
  }
  name    = "${var.name}-srv-${each.key}"
  machine_type = "f1-micro"
  zone         = var.zone
  # service_account {
  #     email  = google_service_account.saj.email
  #     scopes = ["cloud-platform"]
  # }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = each.value
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
  allow_stopping_for_update = true
}
