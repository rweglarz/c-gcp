variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type = list(map(string))
}
