resource "google_service_account" "sa" {
  account_id   = "${var.name}-pan-sa"
  display_name = "${var.name} Firewall Service Account"
}

resource "google_project_iam_member" "p1" {
  project = var.gcp_project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "p2" {
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Service Account for SDGW VMs
resource "google_service_account" "sdgw_sa" {
  account_id   = "${var.name}-sdgw-sa"
  display_name = "${var.name} SDGW Service Account"
}

resource "google_project_iam_member" "sdgw_logging" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sdgw_sa.email}"
}

resource "google_project_iam_member" "sdgw_monitoring" {
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sdgw_sa.email}"
}
