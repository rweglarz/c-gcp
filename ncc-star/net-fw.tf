resource "google_compute_network" "fw" {
  name                    = "${var.name}-fw"
  auto_create_subnetworks = "false"
  routing_mode            = var.vpc_routing_mode
}

resource "google_compute_subnetwork" "fw" {
  for_each      = local.fws

  name          = "${var.name}-fw-${each.key}"
  region        = each.key=="s1" ? local.regions[0] : local.regions[1]
  ip_cidr_range = each.value
  network       = google_compute_network.fw.self_link
}


resource "google_compute_route" "fw_dg" {
  name        = "${var.name}-fw-dg"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.fw.self_link
  next_hop_gateway = "default-internet-gateway"
  priority    = 10
}
