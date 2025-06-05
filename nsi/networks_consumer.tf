resource "google_network_connectivity_hub" "this" {
  provider = google.consumer

  name            = var.name
  preset_topology = "MESH"
}


resource "google_compute_network" "client" {
  for_each = { for k,v in local.cidrs: k=>v if strcontains(k, "client") }
  provider = google.consumer

  name                    = "${var.name}-${each.key}"
  auto_create_subnetworks = "false"
  network_firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
}

resource "google_compute_subnetwork" "client" {
  for_each = google_compute_network.client
  provider = google.consumer

  name          = "${var.name}-${each.key}-s"
  ip_cidr_range = local.cidrs[each.key]
  network       = each.value.id
}


resource "google_network_connectivity_spoke" "consumer"  {
  for_each = google_compute_network.client
  provider = google.consumer

  name = each.key
  location = "global"
  hub = google_network_connectivity_hub.this.id
  linked_vpc_network {
    uri = each.value.self_link
  }
}


resource "google_compute_firewall" "consumer-i" {
  provider = google.consumer
  for_each = google_compute_network.client

  name      = "${var.name}-${each.key}-i"
  network   = each.value.id
  direction = "INGRESS"
  source_ranges = concat(
    [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "35.235.240.0/20", # iap
    ],
    [for r in var.mgmt_ips : r.cidr],
  )
  allow {
    protocol = "all"
  }
}
