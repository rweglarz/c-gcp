module "tc" {
  source = "github.com/PaloAltoNetworks/terraform-google-swfw-modules//modules/vmseries?ref=v2.0.11"

  name                  = "${var.name}-tc"
  custom_image          = "projects/paloaltonetworksgcp-public/global/images/${var.ngfw_image}"
  zone                  = var.zones[0]
  machine_type          = "n2-standard-4"
  service_account       = module.iam_service_account.email
  create_instance_group = false

  bootstrap_options = merge(
    var.bootstrap_options.common,
    var.bootstrap_options.tc,
  )

  network_interfaces = [
    {
      subnetwork       = google_compute_subnetwork.this["mgmt"].self_link
      create_public_ip = false
    },
  ]
}
