variable "name" {
  type    = string
  default = ""
}

variable "cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
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

variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "vpc_routing_mode" {
  default = "GLOBAL"
}

variable "bgp_keep_alive_interval" {
  default = 20    # cloud router default
}

variable "srv_machine_type"{
  type = string
  default = "f1-micro"
}