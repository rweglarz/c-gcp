resource "google_compute_instance" "server-n-s0-a" {
  count        = var.vpc_count
  name         = "${var.name}-n${count.index}-s0-a"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = templatefile("srv_startup.sh", { host = "${var.name}-n${count.index}-s0-b" })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnet_s0[count.index].id
    network_ip = cidrhost(google_compute_subnetwork.data_subnet_s0[count.index].ip_cidr_range, 16)
  }

  tags = [
    "workloads-a"
  ]
}


resource "google_compute_instance" "server-n-s0-b" {
  count        = var.vpc_count
  name         = "${var.name}-n${count.index}-s0-b"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = templatefile("srv_startup.sh", { host = "${var.name}-n${count.index}-s0-b" })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnet_s0[count.index].self_link
    network_ip = cidrhost(google_compute_subnetwork.data_subnet_s0[count.index].ip_cidr_range, 17)
  }

  tags = [
    "workloads-b"
  ]
}


resource "google_compute_instance" "server-p-v0-s0" {
  count        = var.vpc_count
  name         = "${var.name}-p${count.index}-v0-s0"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = file("srv_startup.sh")

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.peered_subnet_v0_s0[count.index].id
    network_ip = cidrhost(google_compute_subnetwork.peered_subnet_v0_s0[count.index].ip_cidr_range, 16)
  }

  tags = [
    "workloads-peered"
  ]
}
