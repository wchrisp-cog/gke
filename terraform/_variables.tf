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

variable "machine_type" {
  description = "The machine type and size used in the node pool. Restricted to low cost machine types. 'e2-medium', 'e2-small', 'e2-micro'"
  type        = string
  default     = "e2-medium"
  validation {
    condition     = contains(["e2-medium", "e2-small", "e2-micro"], var.machine_type)
    error_message = "The machine type is outside the recommended low cost machine type."
  }
}