provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "panka" {
  cidr           = "${google_compute_address.cloud_nat.address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ilb"
}
