variable "gcp_project" {
  type = string
}

variable "mgmt_cidr" {
  type = string
}
variable "data_cidr" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "vpc_count" {
  description = "Number of data vpcs to deploy"
  type = number
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
variable "bootstrap_options_self" {
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

