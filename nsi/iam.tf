resource "google_service_account" "sa" {
  account_id   = "pavm-sa-${var.name}"
  display_name = "${var.name} pan vm sa"
}

resource "google_project_iam_member" "sa" {
  project = var.gcp_project_producer
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa.email}"
}
