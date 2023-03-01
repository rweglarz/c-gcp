variable "name" {
  type    = string
  default = ""
}

variable "cidr" {
  type    = string
  default = "172.21.0.0/23"
}

variable "project" {
  type    = string
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

variable "machine_type" {
  type    = string
  default = "n2-standard-4"
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
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
      cidr = "1.1.1.1"
      desc = "just to not have it empty"
    }
  ]
}

variable "bootstrap_options" {
  type = map(map(string))
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
  default = "pl-029b5d80e69d9bc9e"
}

variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "test_client_ip" {
  type = string
}

variable "log_forwarding" {
 type = string
 default = "panka"
 description = "log forwarding profile from panorama"
}

