locals {
  dns_ttl = 60
}

data "google_dns_managed_zone" "this" {
  name = var.dns_zone
}

resource "google_dns_record_set" "jumphost" {
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "k8s-${var.cid}-jumphost.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.jumphost.network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "api" {
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "k8s-${var.cid}-api.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_address.cp.address
  ]
}

resource "google_dns_record_set" "cp" {
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "k8s-${var.cid}-cp.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.cp.network_interface.0.network_ip
  ]
}

resource "google_dns_record_set" "worker" {
  for_each     = var.nodes.workers
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "k8s-${var.cid}-worker-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.worker[each.key].network_interface.0.network_ip
  ]
}