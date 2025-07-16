variable "name" {
  type    = string
  default = "airs"
}

variable "mgmt_vpc_name" {
  description = "new mgmt vpc"
  type        = string
  default     = "k8st-mgmt"
}
variable "private_vpc_name" {
  description = "existing private vpc"
  type        = string
  default     = "k8st-priv"
}

variable "mgmt_subnet_name" {
  description = "new mgmt subnet"
  type        = string
  default     = "k8st-mgmt-s"
}
variable "private_subnet_name" {
  description = "new private subnet"
  type        = string
  default     = "k8st-priv-s"
}

variable "mgmt_subnet_cidr" {
  default = "172.16.1.0/24"
}
variable "private_subnet_cidr" {
  default = "172.16.2.0/24"
}

variable "project" {
  type = string
}


variable "region" {
  type    = string
  default = "europe-west1"
}

variable "ngfw_service_account_roles" {
  default = [
    "roles/compute.networkViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/viewer",
  ]
}

variable "bootstrap_options" {
  # default = {
  #   common = {
  #     serial-port-enable          = true
  #     dhcp-accept-server-hostname = "yes"
  #     panorama-server             = "cloud"
  #     plugin-op-commands          = "advance-routing:enable"
  #     authcodes                   = "D0000000"
  #     vm-series-auto-registration-pin-id    = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  #     vm-series-auto-registration-pin-value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  #   }
  #   airs = {
  #     dgname             = "folder_airs"
  #   }
  #   tc = {
  #     dgname             = "folder_tc"
  #     plugin-op-commands = "tag_collector_mode_flag:enable"
  #   }
  # }
}

variable "ngfw_replicas" {
  default = 1
}

variable "machine_type" {
  default = "n2-standard-4"
}

variable "ngfw_image" {
  default = "ai-runtime-security-byol-1125h1"
}
