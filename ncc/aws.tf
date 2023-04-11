provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "fwp" {
  for_each       = google_compute_instance.fwp
  cidr           = "${google_compute_instance.fwp[each.key].network_interface.1.access_config.0.nat_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ncc-fwp-${each.key}"
}

resource "aws_ec2_managed_prefix_list_entry" "fws" {
  for_each       = google_compute_instance.fws
  cidr           = "${google_compute_instance.fws[each.key].network_interface.1.access_config.0.nat_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ncc-fws-${each.key}"
}
