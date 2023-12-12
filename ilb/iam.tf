resource "google_service_account" "sa" {
  account_id   = "pan-vm-sa-id"
  display_name = "${var.name}pan vm sa"
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

resource "google_service_account" "saj" {
  account_id   = "${var.name}-jumphost"
  display_name = "${var.name}-jumphost"
}


resource "google_project_iam_custom_role" "vm-logger" {
  role_id     = "vm_logger"
  title       = "vm-logger"
  description = "jump jump"
  permissions = [
    "logging.logEntries.create",
    "monitoring.metricDescriptors.create",
    "monitoring.metricDescriptors.get",
    "monitoring.metricDescriptors.list",
    "monitoring.monitoredResourceDescriptors.get",
    "monitoring.monitoredResourceDescriptors.list",
    "monitoring.timeSeries.create",
  ]
}

resource "google_project_iam_member" "saj" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.vm-logger.id
  member  = "serviceAccount:${google_service_account.saj.email}"
}
