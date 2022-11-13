data "google_dns_managed_zone" "gke" {
  name     = var.dns_zone
}

resource "google_dns_record_set" "ncc-fw" {
  count = 2
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ncc-fw${count.index}.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.fw[count.index].network_interface.1.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "ncc-srv0" {
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ncc-srv0.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.ncc-srv0.network_interface.0.access_config.0.nat_ip
  ]
}

resource "google_dns_record_set" "ncc-srv1" {
  managed_zone = data.google_dns_managed_zone.gke.name
  name = "ncc-srv1.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 300

  rrdatas = [
    google_compute_instance.ncc-srv1.network_interface.0.access_config.0.nat_ip
  ]
}
