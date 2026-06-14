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

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "fw_count" {
  description = "Number of fws to deploy"
  type        = number
  default     = 1
}

variable "fw_machine_type" {
  type    = string
  default = "n2-standard-8"
}

variable "fw_images" {
  type = map(string)
  default = {
    payg    = "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-bundle2-11212"
    default = "projects/paloaltonetworksgcp-public/global/images/vmseries-flex-byol-11212"
  }
}

variable "srv_machine_type" {
  type    = string
  default = "f1-micro"
}

variable "bootstrap_options" {
  type = any
}

variable "ssh_key" {
  type    = string
  default = ""
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
  default     = []
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

variable "labels" {
  type    = map(string)
  default = {}
}

variable "payg" {
  type    = bool
  default = false
}

variable "gcp_panorama_vpc_id" {
  type    = string
  default = null
}

variable "zone" {
  description = "GCP Zone for Compute Engine instances"
  type        = string
  default     = "europe-west1-b"
}
