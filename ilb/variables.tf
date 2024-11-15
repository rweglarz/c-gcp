variable "gcp_project" {
  type = string
}
variable "region" {
  type    = string
  default = "europe-west1"
}

variable "cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "redis_cidr" {
  type = string
  default = "192.168.0.0/29"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "vpc_count" {
  description = "Number of data vpcs to deploy"
  type = number
  default = 2
}
variable "fw_count" {
  description = "Number of fws to deploy"
  type = number
}

variable "fw_machine_type" {
  type = string
  default = "n2-standard-8"
}
variable "srv_machine_type"{
  type = string
  default = "f1-micro"
}

variable "bootstrap_options" {
  type = map
}
variable "bootstrap_options_byol" {
  type = map
}
variable "bootstrap_options_paygo" {
  type = map
}

variable "ssh_key" {
  type = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type = list(map(string))
}


variable "pl-mgmt-csp_nat_ips" {
  type = string
  default = "pl-029b5d80e69d9bc9e"
}

variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "session_resiliency" {
  type    = bool
  default = false
}

variable "session_resiliency_auth" {
  type    = bool
  default = true
}

variable "gcp_panorama_vpc_id" {
  default = null
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
