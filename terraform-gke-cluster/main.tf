provider "google" {
  region      = "us-central1"
}

resource "google_container_cluster" "primary" {
  name                     = "newrelic-php-example"
  zone                     = "us-central1-a"
  initial_node_count       = 1
  remove_default_node_pool = true

  master_auth {
    # Keep empty to disable basic authentication
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    kubernetes_dashboard {
      disabled = true
    }
  }
}

resource "google_container_node_pool" "primary_pool" {
  name       = "standard-pool"
  cluster    = "${google_container_cluster.primary.name}"
  zone       = "us-central1-a"
  node_count = "3"

  node_config {
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 4
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
