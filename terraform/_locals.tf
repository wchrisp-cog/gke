locals {
  network_name           = "${var.cluster_name}-network"
  subnet_name            = "${var.cluster_name}-subnet"
  master_auth_subnetwork = "${var.cluster_name}-master-subnet"
  pods_range_name        = "ip-range-pods-${var.cluster_name}"
  svc_range_name         = "ip-range-svc-${var.cluster_name}"
  subnet_names           = [for subnet_self_link in module.gcp-network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
}