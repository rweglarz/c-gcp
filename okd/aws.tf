provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "okd" {
  cidr           = "${google_compute_address.okd.address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = var.name
}
