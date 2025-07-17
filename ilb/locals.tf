locals {
  cidrs = {
    mgmt      = cidrsubnet(var.cidr, 8, 0)
    public    = cidrsubnet(var.cidr, 8, 1)
    private = {
      a = cidrsubnet(var.cidr, 8, 21)
      b = cidrsubnet(var.cidr, 8, 22)
    }
    psc_nat = {
      a = cidrsubnet(var.cidr, 8, 23)
      b = cidrsubnet(var.cidr, 8, 24)
    }

    private_peers = {
      a = {
        a = cidrsubnet(var.cidr, 8, 211)
        b = cidrsubnet(var.cidr, 8, 212)
      }
      b = {
        a = cidrsubnet(var.cidr, 8, 221)
        b = cidrsubnet(var.cidr, 8, 222)
      }
    }

    private_vpn_peers = {
      a = {
        a = cidrsubnet(var.cidr, 8, 216)
        b = cidrsubnet(var.cidr, 8, 217)
      }
      b = {
        a = cidrsubnet(var.cidr, 8, 226)
      }
    }
  }
  asn = {
    a  = 65510
    b  = 65520
    private-a-vpnpeer-a = 65511
    private-a-vpnpeer-b = 65512
    private-b-vpnpeer-a = 65521
  }

  peering_cidrs = {
    private-a-vpnpeer-a = cidrsubnet("169.254.1.0/24", 7,  0)
    private-a-vpnpeer-b = cidrsubnet("169.254.1.0/24", 7,  1)
    private-b-vpnpeer-a = cidrsubnet("169.254.1.0/24", 7, 32)
  }

  cidrs_p_f = flatten([
    for lk,lv in local.cidrs.private_peers: [
      for pk,pv in lv: {
        n = "private-${lk}-peer-${pk}"
        lk = lk
        pk = pk
        cidr = pv
      }
    ]
  ])
  cidrs_p_m = { for v in local.cidrs_p_f: v.n => v }

  cidrs_v_f = flatten([
    for lk,lv in local.cidrs.private_vpn_peers: [
      for pk,pv in lv: {
        n = "private-${lk}-vpnpeer-${pk}"
        lk = lk
        pk = pk
        cidr = pv
      }
    ]
  ])
  cidrs_v_m = { for v in local.cidrs_v_f: v.n => v }
}

