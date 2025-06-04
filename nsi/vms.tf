resource "google_compute_instance" "servers" {
  provider = google.consumer
  for_each = {
    client-1 = { subnetwork = google_compute_subnetwork.client }
  }
  name                      = "${var.name}-${each.key}"
  machine_type              = var.srv_machine_type
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = each.value.subnetwork.id
    access_config {}
  }
}
