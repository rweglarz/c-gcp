data "google_dns_managed_zone" "this" {
  name     = var.dns_zone
}

resource "google_dns_record_set" "ilb-jumphost" {
  managed_zone = data.google_dns_managed_zone.this.name
  name = "ilb-jumphost.${data.google_dns_managed_zone.this.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_address.jumphost.address
  ]
}

resource "google_dns_record_set" "galb" {
  for_each = toset([
    "ilb-galb-app1",
    "ilb-galb-app2",
  ])
  managed_zone = data.google_dns_managed_zone.this.name
  name = "${each.key}.${data.google_dns_managed_zone.this.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_global_address.galb.address
  ]
}
