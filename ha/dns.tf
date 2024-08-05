data "google_dns_managed_zone" "gke" {
  name     = var.dns_zone
}

resource "google_dns_record_set" "this" {
  for_each = {
    ha-srv0   = google_compute_instance.srv0.network_interface.0.access_config.0.nat_ip,
    ha-srv1   = google_compute_instance.srv1.network_interface.0.access_config.0.nat_ip,
    ha-fw0    = google_compute_instance.fw[0].network_interface.1.access_config.0.nat_ip,
    ha-fw1    = google_compute_instance.fw[1].network_interface.1.access_config.0.nat_ip,
    ha-linux0 = google_compute_instance.linux[0].network_interface.0.access_config.0.nat_ip,
    ha-linux1 = google_compute_instance.linux[1].network_interface.0.access_config.0.nat_ip,
  }

  managed_zone = data.google_dns_managed_zone.gke.name
  name = "${each.key}.${data.google_dns_managed_zone.gke.dns_name}"
  type = "A"
  ttl  = 120

  rrdatas = [
    each.value
  ]
}
