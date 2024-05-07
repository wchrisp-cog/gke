# Example - https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v30.2.0/examples/private_zonal_with_networking
# Reference material - https://github.com/murphye/cheap-gke-cluster

# K8s Network
module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 7.5"

  project_id   = var.project_id
  network_name = local.network_name

  subnets = [
    {
      subnet_name           = local.subnet_name
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

#K8s Router/NAT for external network requests (Internet Access)
resource "google_compute_router" "router" {
  name    = "${local.network_name}-router"
  project = module.gcp-network.project_id
  region  = var.region
  network = module.gcp-network.network_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  project                            = google_compute_router.router.project
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# K8s Cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 30.0"

  project_id = var.project_id
  name       = var.cluster_name
  regional   = false
  region     = var.region
  zones      = [var.cluster_zone]

  network                  = module.gcp-network.network_name
  subnetwork               = module.gcp-network.subnets_names[0]
  ip_range_pods            = local.pods_range_name
  ip_range_services        = local.svc_range_name
  create_service_account   = true
  enable_private_endpoint  = false
  enable_private_nodes     = true
  master_ipv4_cidr_block   = "172.16.0.0/28"
  deletion_protection      = false
  logging_service          = "none"
  remove_default_node_pool = true

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = var.machine_type
      min_count          = 1
      max_count          = 2
      local_ssd_count    = 0
      spot               = true
      disk_size_gb       = 20
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      logging_variant    = "DEFAULT"
      auto_repair        = true
      auto_upgrade       = true
      initial_node_count = 2
    },
  ]

  master_authorized_networks = [
    # Allow yourself to connect to cluster from local device
    {
      cidr_block   = "${data.http.ip.response_body}/32"
      display_name = "Me"
    }
    # {
    #   cidr_block   = data.google_compute_subnetwork.subnet.ip_cidr_range
    #   display_name = "VPC"
    # },
  ]
}

# Workload Identity roles
module "workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "${var.cluster_name}-applications"
  namespace  = "default"
  project_id = var.project_id
  roles      = []
}

module "workload-identity-2" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "${var.cluster_name}-external-secrets"
  namespace  = "default"
  project_id = var.project_id
  roles      = []
}
