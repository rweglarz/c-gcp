variable "name" {
  type    = string
  default = "rwe-k8s-native"
}

variable "cid" {
  description = "cluster id/name"
  type    = string
  default = "c5"
}

variable "cidr" {
  type    = string
  default = "172.21.0.0/23"
}

variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"

}
variable "zone" {
  type    = string
  default = "europe-west1-b"
}



variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
  default = [
    {
      cidr        = "192.0.2.1/32"
      description = "test-net"
    }
  ]
}

variable "tmp_ips" {
  description = "List of tmp IPs allowed external access"
  type        = list(map(string))
  default = [
    {
      cidr = "192.0.2.1/32"
      desc = "just to not have it empty"
    }
  ]
}

variable "gcp_ips" {
  type = list(map(string))
  default = [
    {
      cidr        = "130.211.0.0/22"
      description = ""
    },
    {
      cidr        = "35.191.0.0/16"
      description = ""
    },
    {
      cidr        = "35.235.240.0/20"
      description = ""
    },
    {
      cidr        = "209.85.152.0/22"
      description = ""
    },
    {
      cidr        = "209.85.204.0/22"
      description = ""
    },
  ]
}

variable "nodes" {
  default = {
    workers = {
      1 = {}
      2 = {}
    }
  }
}

variable "gcp_panorama_vpc_id" {
  default = null
}
