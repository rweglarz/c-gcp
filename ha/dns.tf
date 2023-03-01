data "google_dns_managed_zone" "gke" {
  name     = var.dns_zone
}

resource "google_dns_record_set" "fw" {
  count = 2
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ha-fw${count.index}.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.fw[count.index].network_interface.1.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "srv0" {
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ha-srv0.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.srv0.network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "srv1" {
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ha-srv1.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.srv1.network_interface.0.access_config.0.nat_ip
  ]
}
