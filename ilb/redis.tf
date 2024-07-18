resource "google_redis_instance" "this" {
  count = (var.session_resiliency==true) ? 1 : 0

  name           = var.name
  memory_size_gb = 2
  auth_enabled   = var.session_resiliency_auth

  reserved_ip_range = var.redis_cidr

  authorized_network = google_compute_network.mgmt.id
  
  read_replicas_mode = "READ_REPLICAS_DISABLED"  # explicit
  connect_mode       = "DIRECT_PEERING"          # explicit
}

output "redis_endpoint" {
  value     = try("${google_redis_instance.this[0].host}:${google_redis_instance.this[0].port}", null)
}

output "redis_auth" {
  value     = try(google_redis_instance.this[0].auth_string, null)
  sensitive = true
}
