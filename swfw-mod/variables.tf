variable "name" {
  type    = string
  default = "swfw-mod"
}

variable "cidr" {
  type    = string
  default = "172.17.0.0/20"
}

variable "project" {
  type = string
}
variable "region" {
  type    = string
  default = "europe-west1"
}
variable "zones" {
  type = list(string)
  default = [
    "europe-west1-b",
    "europe-west1-c",
  ]
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

variable "ngfw_service_accont_roles" {
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
  # serial-port-enable          = true
  # dhcp-accept-server-hostname = "yes"
  # panorama-server             = "cloud"
  # plugin-op-commands          = "advance-routing:enable"
  # dgname                      = "folder"
  # authcodes                   = "D0000000"
  # vm-series-auto-registration-pin-id    = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  # vm-series-auto-registration-pin-value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
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
