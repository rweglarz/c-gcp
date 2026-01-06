resource "google_network_security_intercept_deployment_group" "this" {
  intercept_deployment_group_id = "dg-in-band"
  location                      = "global"
  network                       = google_compute_network.nsi["in-band"].id
}

resource "google_network_security_intercept_deployment" "this" {
  for_each = { for k,v in local.nsi_to_zones: k => v if v.is_mirror==false }

  intercept_deployment_id    = "id-${each.key}"
  location                   = each.value["zone"]
  forwarding_rule            = google_compute_forwarding_rule.nsi[each.key].id
  intercept_deployment_group = google_network_security_intercept_deployment_group.this.id
}



resource "google_network_security_mirroring_deployment_group" "this" {
  mirroring_deployment_group_id = "dg-out-of-band"
  location                      = "global"
  network                       = google_compute_network.nsi["out-of-band"].id
}

resource "google_network_security_mirroring_deployment" "this" {
  for_each = { for k,v in local.nsi_to_zones: k => v if v.is_mirror==true }

  mirroring_deployment_id    = "id-${each.key}"
  location                   = each.value["zone"]
  forwarding_rule            = google_compute_forwarding_rule.nsi[each.key].id
  mirroring_deployment_group = google_network_security_mirroring_deployment_group.this.id
}
