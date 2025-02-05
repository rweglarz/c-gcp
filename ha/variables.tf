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
variable "zones" {
  type = list(string)
  default = [
    "europe-west1-b",
    "europe-west1-c",
  ]
}

variable "srv_type" {
  type    = string
  default = "e2-micro"
}

variable "machine_type" {
  type    = string
  default = "n2-standard-4"
}

variable "fw_image" {
  type    = string
  default = "flex-byol-1114"
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
  type = string
  default = ""
}

variable "vpn_psk" {
  type = string
}

variable "gcp_panorama_vpc_id" {
  default = null
}
