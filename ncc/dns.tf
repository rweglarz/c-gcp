locals {
  dns_ttl = 60
}

data "google_dns_managed_zone" "this" {
  name = var.dns_zone
}

resource "google_dns_record_set" "fwp" {
  for_each     = google_compute_instance.fwp
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-fwp-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.fwp[each.key].network_interface.1.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "fws" {
  for_each     = google_compute_instance.fws
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-fws-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.fws[each.key].network_interface.1.access_config.0.nat_ip
  ]
}


resource "google_dns_record_set" "srv_app0" {
  for_each     = google_compute_instance.srv_app0
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-srv-app0-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.srv_app0[each.key].network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "srv_app1" {
  for_each     = google_compute_instance.srv_app1
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-srv-app1-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.srv_app1[each.key].network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "srv_ext" {
  for_each     = google_compute_instance.srv_ext
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-srv-ext-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_instance.srv_ext[each.key].network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "glb" {
  for_each     = var.global_services
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-glb-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_global_forwarding_rule.ext[each.key].ip_address
  ]
}

resource "google_dns_record_set" "nlb" {
  for_each     = var.networks["internet"]
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-nlb-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = local.dns_ttl

  rrdatas = [
    google_compute_forwarding_rule.ext[each.key].ip_address
  ]
}
