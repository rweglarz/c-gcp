locals {
  subnet_prefix_length = 28
  bootstrap_options = {
  }
  private_ips = {
    fwp = { for r,v in var.networks.mgmt : r => {
      mgmt_ip   = cidrhost(google_compute_subnetwork.mgmt[r].ip_cidr_range, 5)
      eth1_1_ip = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 5)
      eth1_1_gw = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 1)
      eth1_2_ip = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 5)
      eth1_2_gw = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 1)
      }
    }
  }
}
