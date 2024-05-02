variable "project_id" {
  description = "GCP Project to deploy to."
  type        = string
}

variable "region" {
  description = "GCP Region to deploy to."
  type        = string
}

variable "cluster_zone" {
  description = "GCP GKE Cluster Zone"
  type        = string
}

variable "cluster_name" {
  description = "GCP GKE Cluster Name"
  type        = string
}