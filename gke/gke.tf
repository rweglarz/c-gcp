resource "google_service_account" "gke" {
  account_id   = "${var.name}-sa"
  display_name = "${var.name}-gke-sa"
}

resource "google_project_iam_member" "gke" {
  project = var.project
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke.email}"
}


resource "google_container_cluster" "gke" {
  name     = var.name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version         = var.gke_version
  datapath_provider          = "ADVANCED_DATAPATH"
  # enable_fqdn_network_policy = true

  network         = google_compute_network.gke.self_link
  subnetwork      = google_compute_subnetwork.gke.self_link
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block = ""
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = concat(var.mgmt_ips, var.extra_ips)
      content {
        cidr_block   = cidr_blocks.value.cidr
        display_name = cidr_blocks.value.description
      }
    }
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.m_cidr
  }

  depends_on = [ 
    google_project_iam_member.gke
  ]
}

resource "google_container_node_pool" "np1" {
  name     = "${var.name}-np1"
  location = var.region
  cluster  = google_container_cluster.gke.name

  node_count = 1
  version    = var.gke_version

  node_config {
    preemptible  = false
    machine_type = "n2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  lifecycle {
    ignore_changes = [ 
      version
    ]
  }
}
