resource "google_network_connectivity_hub" "this" {
  name            = var.name
  policy_mode     = "PRESET"
  preset_topology = "STAR"
}

resource "google_network_connectivity_group" "center"  {
 hub         = google_network_connectivity_hub.this.id
 name        = "center"
 auto_accept {
   auto_accept_projects = [ var.project ]
 }
}

resource "google_network_connectivity_group" "edge"  {
 hub         = google_network_connectivity_hub.this.id
 name        = "edge"
 auto_accept {
   auto_accept_projects = [ var.project ]
 }
}

