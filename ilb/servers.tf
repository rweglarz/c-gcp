resource "google_compute_instance" "servers" {
  for_each = {
    private-a-1    = { subnetwork = google_compute_subnetwork.private["a"], tags = [ "workloads-pbr" ] }
    private-a-2    = { subnetwork = google_compute_subnetwork.private["a"], tags = [ "workloads-pbr" ] }
    private-b      = { subnetwork = google_compute_subnetwork.private["b"] }
    peer-a-a-1     = { subnetwork = google_compute_subnetwork.peer["private-a-peer-a"], tags = [ "workloads-pbr" ] }
    peer-a-a-2     = { subnetwork = google_compute_subnetwork.peer["private-a-peer-b"], tags = [ "workloads-pbr" ] }
    vpnpeer-a-a-1  = { subnetwork = google_compute_subnetwork.vpnpeer["private-a-vpnpeer-a"] }
    vpnpeer-a-b-1  = { subnetwork = google_compute_subnetwork.vpnpeer["private-a-vpnpeer-b"] }
  }
  name         = "${var.name}-${each.key}"
  machine_type = var.srv_machine_type
  allow_stopping_for_update = true

  #metadata_startup_script = templatefile("srv_startup.sh", { host = "${var.name}-n${count.index}-s0-b" })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = each.value.subnetwork.id
    network_ip = cidrhost(each.value.subnetwork.ip_cidr_range, 11 + (endswith(each.key, "-2")? 1 : 0))
  }
  tags = try(each.value.tags, null)

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}
