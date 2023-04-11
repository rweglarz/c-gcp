data "google_dns_managed_zone" "this" {
  name = var.dns_zone
}

resource "google_dns_record_set" "fwp" {
  for_each     = google_compute_instance.fwp
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-fwp-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = 300

  rrdatas = [
    google_compute_instance.fwp[each.key].network_interface.1.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "fws" {
  for_each     = google_compute_instance.fws
  managed_zone = data.google_dns_managed_zone.this.name
  name         = "ncc-fws-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type         = "A"
  ttl          = 300

  rrdatas = [
    google_compute_instance.fws[each.key].network_interface.1.access_config.0.nat_ip
  ]
}


resource "google_dns_record_set" "srv0" {
  for_each     = google_compute_instance.srv0
  managed_zone = data.google_dns_managed_zone.this.name
  name = "ncc-srv0-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.srv0[each.key].network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "srv1" {
  for_each     = google_compute_instance.srv1
  managed_zone = data.google_dns_managed_zone.this.name
  name = "ncc-srv1-${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.srv1[each.key].network_interface.0.access_config.0.nat_ip
  ]
}
