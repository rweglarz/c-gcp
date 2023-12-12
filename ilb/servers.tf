resource "google_compute_instance" "server-a" {
  count        = var.vpc_count - 1
  name         = "${var.name}-srv-${count.index+1}-a"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = file("srv_startup.sh")

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnets[count.index+1].id
    network_ip =  cidrhost(google_compute_subnetwork.data_subnets[count.index+1].ip_cidr_range, 80)
  }
  tags = [
    "workloads"
  ]
}


resource "google_compute_instance" "server-b" {
  count        = var.vpc_count - 1
  name         = "${var.name}-srv-${count.index+1}-b"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = file("srv_startup.sh")

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnets[count.index+1].id
    network_ip =  cidrhost(google_compute_subnetwork.data_subnets[count.index+1].ip_cidr_range, 85)
  }
}


resource "google_compute_instance" "server-c" {
  count        = var.vpc_count - 1
  name         = "${var.name}-srv-${count.index+1}-c"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  metadata_startup_script = file("srv_startup.sh")

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.peered_subnets[count.index+1].id
    network_ip =  cidrhost(google_compute_subnetwork.peered_subnets[count.index+1].ip_cidr_range, 80)
  }
  tags = [
    "workloads"
  ]
}
