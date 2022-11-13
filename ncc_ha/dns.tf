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
