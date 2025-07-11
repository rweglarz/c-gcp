resource "google_compute_instance" "fw" {
  for_each = google_compute_subnetwork.fw

  name         = "${var.name}-fw-${each.key}"
  machine_type = var.srv_machine_type
  zone         = data.google_compute_zones.this[each.value.region].names[0]
  allow_stopping_for_update = true

  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = each.value.id
    network_ip = cidrhost(each.value.ip_cidr_range, 3)
    access_config {}
  }

  lifecycle {
    ignore_changes = [ 
      boot_disk[0].initialize_params[0].image 
    ]
  }
  tags = [
    "firewall",
  ]
}

resource "google_compute_instance" "server" {
  for_each = google_compute_subnetwork.spoke

  name         = "${var.name}-${each.key}"
  machine_type = var.srv_machine_type
  zone         = data.google_compute_zones.this[each.value.region].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = each.value.id
    network_ip = cidrhost(each.value.ip_cidr_range, 3)
  }

  lifecycle {
    ignore_changes = [ 
      boot_disk[0].initialize_params[0].image 
    ]
  }
}
