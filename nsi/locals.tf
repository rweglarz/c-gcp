locals {
  cidrs = {
    mgmt            = cidrsubnet(var.cidr, 8, 0)
    nsi_in_band     = cidrsubnet(var.cidr, 8, 1)
    nsi_out_of_band = cidrsubnet(var.cidr, 8, 2)
    ncc_vpc_vpn     = cidrsubnet(var.cidr, 8, 100)
    client1         = cidrsubnet(var.cidr, 8, 101)
    client2         = cidrsubnet(var.cidr, 8, 102)
    client3         = cidrsubnet(var.cidr, 8, 103)
    peer_vpc_vpn    = cidrsubnet(var.cidr, 8, 200)
    peering         = "169.254.1.0/24"
  }
  nsi = {
    "in-band" = {
      cidr      = local.cidrs["nsi_in_band"]
      is_mirror = false
    }
    "out-of-band" = {
      cidr      = local.cidrs["nsi_out_of_band"]
      is_mirror = true
    }
  }
  nsi_to_zones_m = flatten([
    for kn, vn in local.nsi : [
      for z in data.google_compute_zones.this.names : {
        name      = format("%s--%s", kn, z)
        nsi_type  = kn
        zone      = z
        is_mirror = vn.is_mirror
      }
    ]
  ])
  nsi_to_zones = { for k, v in local.nsi_to_zones_m : v.name => v }
}

