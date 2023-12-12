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
