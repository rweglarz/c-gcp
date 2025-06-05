locals {
  cidrs = {
    mgmt    = cidrsubnet(var.cidr, 8, 0)
    private = cidrsubnet(var.cidr, 8, 1)
    client1 = cidrsubnet(var.cidr, 8, 101)
    client2 = cidrsubnet(var.cidr, 8, 102)
    client3 = cidrsubnet(var.cidr, 8, 103)
  }
}

