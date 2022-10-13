variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "name" {
  type = string
}
variable "cidr" {
  type = string
}
variable "m_cidr" {
  type = string
}
variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}
