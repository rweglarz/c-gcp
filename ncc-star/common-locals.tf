locals {
  regions = [
    "europe-west1",
    "us-east1",
  ]
  region_to_vpn = {
    europe-west1 = {
      peering = [
        "169.254.1.0/30",
        "169.254.1.4/30",
      ]
    }
    us-east1 = {
      peering = [
        "169.254.2.0/30",
        "169.254.2.4/30",
      ]
    }
  }
  fws = {
    s1 = cidrsubnet(var.cidr, 8, 128)
    s2 = cidrsubnet(var.cidr, 8, 129)
  }
  centers = {
    s1 = cidrsubnet(var.cidr, 8, 0)
    s2 = cidrsubnet(var.cidr, 8, 1)
  }
  spokes = {
    spoke1 = {
      s1 = cidrsubnet(var.cidr, 8, 16)
      s2 = cidrsubnet(var.cidr, 8, 17)
    }
    spoke2 = {
      s1 = cidrsubnet(var.cidr, 8, 24)
      s2 = cidrsubnet(var.cidr, 8, 25)
    }
  }
  spoke_subnets_t = flatten([
    for spoke_name, spoke_details in local.spokes : [
      for subnet_name, subnet_cidr in spoke_details : {
        name        = "${spoke_name}-${subnet_name}"
        cidr        = subnet_cidr
        spoke_name  = spoke_name
        subnet_name = subnet_name
      }
    ]
  ])
  spoke_subnets = { for subnet_detail in local.spoke_subnets_t: subnet_detail.name => subnet_detail }
}