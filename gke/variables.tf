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

variable "gcp_panorama_vpc_id" {
  default = null
}

