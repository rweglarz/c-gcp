locals {
  cidrs = {
    mgmt       = cidrsubnet(var.cidr, 8, 0)
    public     = cidrsubnet(var.cidr, 8, 1)
    vpn        = cidrsubnet(var.cidr, 8, 2)
    private    = cidrsubnet(var.cidr, 8, 3)
    workload-a = cidrsubnet(var.cidr, 8, 8)
    workload-b = cidrsubnet(var.cidr, 8, 9)
    remote     = cidrsubnet(var.cidr, 8, 201)
  }

  asn = {
    # Cloud Routers
    vpn_router    = 65504
    remote_router = 65505
    
    # SD-WAN Gateways
    sdgw1 = 65511
    sdgw2 = 65512
  }

  # SDGW VM static IP allocations inside the vpn VPC
  sdgw_ips = {
    sdgw1 = cidrhost(local.cidrs.vpn, 10)
    sdgw2 = cidrhost(local.cidrs.vpn, 11)
  }

  # Local Cloud Router IPs inside the vpn VPC for direct peering
  vpn_router_ips = {
    primary   = cidrhost(local.cidrs.vpn, 2)
    redundant = cidrhost(local.cidrs.vpn, 3)
  }

  # IPSec Tunnel configurations (Overlay network link-local APIPA ranges - Full Mesh)
  tunnel_cidrs = {
    sdgw1_t1 = "169.254.31.0/30"
    sdgw1_t2 = "169.254.31.4/30"
    sdgw2_t1 = "169.254.32.0/30"
    sdgw2_t2 = "169.254.32.4/30"
  }

  # Dynamically derived BGP IPs for both sides of the IPsec tunnels
  tunnel_ips = {
    sdgw1_t1 = {
      router_ip = cidrhost(local.tunnel_cidrs.sdgw1_t1, 1)
      sdgw_ip   = cidrhost(local.tunnel_cidrs.sdgw1_t1, 2)
    }
    sdgw1_t2 = {
      router_ip = cidrhost(local.tunnel_cidrs.sdgw1_t2, 1)
      sdgw_ip   = cidrhost(local.tunnel_cidrs.sdgw1_t2, 2)
    }
    sdgw2_t1 = {
      router_ip = cidrhost(local.tunnel_cidrs.sdgw2_t1, 1)
      sdgw_ip   = cidrhost(local.tunnel_cidrs.sdgw2_t1, 2)
    }
    sdgw2_t2 = {
      router_ip = cidrhost(local.tunnel_cidrs.sdgw2_t2, 1)
      sdgw_ip   = cidrhost(local.tunnel_cidrs.sdgw2_t2, 2)
    }
  }
}
