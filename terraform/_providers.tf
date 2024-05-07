terraform {
  required_version = ">= 1.8.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.27.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
  # If you would like to use gcs as a backend
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    project    = "gke-playground"
    repository = "https://github.com/wchrisp-cog/gke/tree/main"
  }
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

