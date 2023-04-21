variable "name" {
  type    = string
  default = ""
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

variable "networks" {
  description = "networks and subnets"
  default = {
    mgmt = {
      europe-west1 = {
        idx = 0
      }
      europe-west2 = {
        idx = 16
      }
    }
    internet = {
      europe-west1 = {
        idx = 1
      }
      europe-west2 = {
        idx = 17
      }
    }
    internal = {
      europe-west1 = {
        idx = 2
      }
      europe-west2 = {
        idx = 18
      }
    }
    ha = {
      europe-west1 = {
        idx = 3
      }
      europe-west2 = {
        idx = 19
      }
    }
    srv_app0 = {
      europe-west1 = {
        idx = 4
      }
      europe-west2 = {
        idx = 20
      }
    }
    srv_app1 = {
      europe-west1 = {
        idx = 5
      }
      europe-west2 = {
        idx = 21
      }
    }
  }
}

variable "machine_type" {
  type    = string
  default = "n2-standard-4"
}

variable "fw_image" {
  type    = string
  default = "flex-byol-1019"
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

variable "bootstrap_options" {
  type = map(map(string))
  default = {
    common = {
      op-command-modes            = "mgmt-interface-swap"
      serial-port-enable          = true
      dhcp-accept-server-hostname = "yes"
      #authcodes =
      #ssh-keys = will override the key from ssh_key_path
    }
    fw0 = {
    }
    fw1 = {
    }
  }

}

variable "pl-mgmt-csp_nat_ips" {
  type        = string
  description = "prefix list for aws sg"
}

variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "test_client_ip" {
  type = string
}

variable "log_forwarding" {
  type        = string
  default     = "panka"
  description = "log forwarding profile from panorama"
}

variable "ssh_key_path" {
  type    = string
  default = ""
}

variable "asn" {
  default = {
    ncc_internet = "65501"
    fw           = "65002"
    ncc_internal = "65503"
  }
}

variable "routing_mode" {
  default = "GLOBAL"
}

variable "global_services" {
  default = {
    s1 = "8081",
    s2 = "8082",
  }
}
