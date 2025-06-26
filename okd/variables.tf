variable "name" {
  type = string
  default = "okd"
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
  type = list(map(string))
}

variable "cidr" {
  type = string
  default = "172.29.32.0/19"
}

variable "azure_vpn_ips" {
  type = list(string)
}

variable "vpn_psk" {
  type = string
}

variable "gcp_panorama_vpc_id" {
  default = null
}

variable "airs_vpc_id" {
  default = null
}
