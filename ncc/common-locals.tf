locals {
  subnet_prefix_length = 28
  bootstrap_options = {
  }
  local_vpcs = {
    "europe-west1" = cidrsubnet(var.cidr, 1, 0)
    "europe-west2" = cidrsubnet(var.cidr, 1, 1)
  }
  private_ips = {
    fwp = { for r,v in var.networks.mgmt : r => {
      mgmt_ip   = cidrhost(google_compute_subnetwork.mgmt[r].ip_cidr_range, 5)
      eth1_1_ip = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 5)
      eth1_1_gw = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 1)
      eth1_2_ip = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 5)
      eth1_2_gw = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 1)
      eth1_3_ip = cidrhost(google_compute_subnetwork.ha[r].ip_cidr_range, 5)
      eth1_3_gw = cidrhost(google_compute_subnetwork.ha[r].ip_cidr_range, 1)
      }
    }
    fws = { for r,v in var.networks.mgmt : r => {
      mgmt_ip   = cidrhost(google_compute_subnetwork.mgmt[r].ip_cidr_range, 6)
      eth1_1_ip = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 6)
      eth1_1_gw = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 1)
      eth1_2_ip = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 6)
      eth1_2_gw = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 1)
      eth1_3_ip = cidrhost(google_compute_subnetwork.ha[r].ip_cidr_range, 6)
      eth1_3_gw = cidrhost(google_compute_subnetwork.ha[r].ip_cidr_range, 1)
      }
    }
    cr_internal = { for r, v in var.networks.internal : r => {
      intf_p_ip = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 7)
      intf_r_ip = cidrhost(google_compute_subnetwork.internal[r].ip_cidr_range, 8)
      }
    }
    cr_internet = { for r, v in var.networks.internet : r => {
      intf_p_ip = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 7)
      intf_r_ip = cidrhost(google_compute_subnetwork.internet[r].ip_cidr_range, 8)
      }
    }
  }
}
