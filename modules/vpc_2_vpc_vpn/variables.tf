variable "name" {
}

variable "vpc_a_id" {
}
variable "vpc_b_id" {
}

variable "vpc_a_name" {
}
variable "vpc_b_name" {
}

variable "vpc_a_asn" {
}
variable "vpc_b_asn" {
}

variable "region" {
}

variable "peering_cidrs" {
}

variable "advertised_ip_ranges_a" {
  default = []
}
variable "advertised_ip_ranges_b" {
  default = []
}
