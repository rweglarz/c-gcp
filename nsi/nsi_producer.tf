resource "google_network_security_intercept_deployment_group" "this" {
  intercept_deployment_group_id = "dg"
  location                      = "global"
  network                       = google_compute_network.private.id
}

resource "google_network_security_intercept_deployment" "this" {
  for_each = toset(data.google_compute_zones.this.names)

  intercept_deployment_id    = "id-${each.key}"
  location                   = each.key
  forwarding_rule            = google_compute_forwarding_rule.private[each.key].id
  intercept_deployment_group = google_network_security_intercept_deployment_group.this.id
}
