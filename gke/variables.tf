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
  type    = string
  default = "172.30.0.0/16"
}
variable "m_cidr" {
  type    = string
  default = "172.29.254.240/28"
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}
variable "extra_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "gcp_panorama_vpc_id" {
  default = null
}

variable "gke_version" {
  default = "1.31"
}


variable "psc_attachment" {
  default = null
}
