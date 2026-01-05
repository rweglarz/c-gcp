variable "gcp_project_producer" {
  type = string
}
variable "gcp_project_consumer" {
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

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "fw_count" {
  description = "Number of fws to deploy"
  type        = number
}
variable "fw_image" {
  default = {
    airs_byol = "ai-runtime-security-byol-1129"
    vm_payg   = "vmseries-flex-bundle2-1126"
    vm_byol   = "vmseries-flex-byol-1128"
  }
}

variable "fw_machine_type" {
  type    = string
  default = "n2-standard-8"
}
variable "srv_machine_type" {
  type    = string
  default = "f1-micro"
}

variable "bootstrap_options" {
  type = map(any)
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "dns_zone" {
  type    = string
  default = "w-gcp"
}

variable "gcp_panorama_vpc_id" {
  default = null
}

variable "airs" {
  type    = bool
  default = false
}

variable "payg" {
  type    = bool
  default = false
}

variable "consumer_org" {
  type = string
}

variable "consumer_sa" {
  type = string
}

variable "consumer_folder" {
  type    = string
}
