provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "fw" {
  count = 2
  cidr           = "${google_compute_instance.fw[count.index].network_interface.1.access_config.0.nat_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-gcp-ha-fw${count.index}"
}
