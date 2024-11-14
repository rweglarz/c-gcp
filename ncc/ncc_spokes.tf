resource "google_compute_network" "test1" {
  name = "${var.name}-test1"

  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "test1" {
  name          = "${var.name}-test1"
  region        = var.region
  ip_cidr_range = "172.25.1.0/28"
  network       = google_compute_network.test1.id
}

resource "google_network_connectivity_spoke" "test1" {
  name     = "${var.name}-test1"
  hub      = google_network_connectivity_hub.internal.id
  location = "global"
  linked_vpc_network {
    uri = google_compute_network.test1.self_link
  }
}

resource "google_compute_firewall" "test1" {
  name      = "${var.name}-test1"
  network   = google_compute_network.test1.id
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : r.cidr],
    [for r in var.gcp_ips  : r.cidr],
    [for r in var.tmp_ips  : r.cidr],
  )
  allow {
    protocol = "all"
  }
}



resource "google_compute_network" "test2" {
  name = "${var.name}-test2"

  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "test2" {
  name          = "${var.name}-test2"
  region        = var.region
  ip_cidr_range = "172.25.2.0/28"
  network       = google_compute_network.test2.id
}

resource "google_network_connectivity_spoke" "test2" {
  name     = "${var.name}-test2"
  hub      = google_network_connectivity_hub.internal.id
  location = "global"
  linked_vpc_network {
    uri = google_compute_network.test2.self_link
  }
}

resource "google_compute_firewall" "test2" {
  name      = "${var.name}-test2"
  network   = google_compute_network.test2.id
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ],
    [for r in var.mgmt_ips : r.cidr],
    [for r in var.gcp_ips  : r.cidr],
    [for r in var.tmp_ips  : r.cidr],
  )
  allow {
    protocol = "all"
  }
}


resource "google_compute_instance" "srv_test1" {
  name         = "${var.name}-srv-test1"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[var.region].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.test1.id
    network_ip = cidrhost(google_compute_subnetwork.test1.ip_cidr_range, 9)
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
    ]
  }
}

resource "google_compute_instance" "srv_test2" {
  name         = "${var.name}-srv-test2"
  machine_type = "f1-micro"
  zone         = data.google_compute_zones.available[var.region].names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.test2.id
    network_ip = cidrhost(google_compute_subnetwork.test2.ip_cidr_range, 9)
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
    ]
  }
}
