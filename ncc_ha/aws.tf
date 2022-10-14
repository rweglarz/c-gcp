provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "panka-fw0" {
  cidr           = "${google_compute_instance.fw[0].network_interface.1.access_config.0.nat_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ncc-fw0"
}
resource "aws_ec2_managed_prefix_list_entry" "panka-fw1" {
  cidr           = "${google_compute_instance.fw[1].network_interface.1.access_config.0.nat_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ncc-fw1"
}
