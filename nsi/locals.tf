locals {
  cidrs = {
    mgmt    = cidrsubnet(var.cidr, 8, 0)
    private = cidrsubnet(var.cidr, 8, 1)
    client  = cidrsubnet(var.cidr, 8, 101)
  }
}

