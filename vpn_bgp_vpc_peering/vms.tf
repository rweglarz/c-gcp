data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "client11" {
  name                      = "client11"
  machine_type              = "n2-standard-2"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.network11_subnet1.id
    network_ip = cidrhost(google_compute_subnetwork.network11_subnet1.ip_cidr_range, 10)
    access_config {}
  }
}

resource "google_compute_instance" "client1" {
  name                      = "client1"
  machine_type              = "n2-standard-2"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.network1_subnet1.id
    network_ip = cidrhost(google_compute_subnetwork.network1_subnet1.ip_cidr_range, 10)
    access_config {}
  }
}


resource "google_compute_instance" "client2" {
  name                      = "client2"
  machine_type              = "n2-standard-2"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.network2_subnet1.id
    network_ip = cidrhost(google_compute_subnetwork.network2_subnet1.ip_cidr_range, 10)
    access_config {}
  }
}

resource "google_compute_instance" "client3" {
  name                      = "client3"
  machine_type              = "n2-standard-2"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.network3_subnet1.id
    network_ip = cidrhost(google_compute_subnetwork.network3_subnet1.ip_cidr_range, 10)
    access_config {}
  }
}

output "pub-client11"{
  value = google_compute_instance.client11.network_interface[0].access_config[0].nat_ip
}
output "pub-client1"{
  value = google_compute_instance.client1.network_interface[0].access_config[0].nat_ip
}
output "pub-client2"{
  value = google_compute_instance.client2.network_interface[0].access_config[0].nat_ip
}
output "pub-client3"{
  value = google_compute_instance.client3.network_interface[0].access_config[0].nat_ip
}

