resource "google_compute_network" "network11" {
  name                    = "network11"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "network11_subnet1" {
  name          = "net11-subnet-1"
  ip_cidr_range = "10.0.11.0/25"
  region        = "us-central1"
  network       = google_compute_network.network11.id
}

resource "google_compute_subnetwork" "network11_subnet2" {
  name          = "net11-subnet-2"
  ip_cidr_range = "10.0.11.128/25"
  region        = "us-west1"
  network       = google_compute_network.network11.id
}


resource "google_compute_network_peering" "peering1" {
  name                 = "peering1"
  network              = google_compute_network.network11.self_link
  peer_network         = google_compute_network.network1.self_link
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "peering2" {
  name                 = "peering2"
  network              = google_compute_network.network1.self_link
  peer_network         = google_compute_network.network11.self_link
  export_custom_routes = true
  import_custom_routes = true
}
