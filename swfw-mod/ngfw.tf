module "iam_service_account" {
  source = "github.com/PaloAltoNetworks/terraform-google-swfw-modules//modules/iam_service_account?ref=v2.0.11"

  service_account_id = var.name
  display_name       = var.name
  roles              = var.ngfw_service_accont_roles
  project_id         = var.project
}

module "ngfw" {
  source = "github.com/PaloAltoNetworks/terraform-google-swfw-modules//modules/autoscale?ref=v2.0.11"

  name                  = "${var.name}-ngfw"
  project_id            = var.project
  region                = var.region
  regional_mig          = true
  service_account_email = module.iam_service_account.email

  image                 = "projects/paloaltonetworksgcp-public/global/images/${var.ngfw_image}"
  machine_type          = var.machine_type
  min_vmseries_replicas = var.ngfw_replicas
  max_vmseries_replicas = var.ngfw_replicas
  autoscaler_metrics = {
    "custom.googleapis.com/VMSeries/panSessionUtilization" = {
      target = 50
      filter = "resource.type = \"gce_instance\""
      type   = "GAUGE"
    }
  }

  network_interfaces = [
    {
      subnetwork       = google_compute_subnetwork.this["mgmt"].id
      create_public_ip = false
    },
    {
      subnetwork       = google_compute_subnetwork.this["private"].id
      create_public_ip = false
    },
  ]

  metadata = var.bootstrap_options
}

module "lb_internal" {
  #   source = "github.com/PaloAltoNetworks/terraform-google-swfw-modules//modules/lb_internal?ref=v2.0.11"
  source = "../modules/swfw__lb_internal"

  name              = var.name
  region            = var.region
  health_check_port = "80"
  backends = {
    airs = module.ngfw.regional_instance_group_id
  }
  network    = google_compute_network.this["private"].self_link
  subnetwork = google_compute_subnetwork.this["private"].self_link

  ip_protocol = "UDP"
  all_ports   = true
}
