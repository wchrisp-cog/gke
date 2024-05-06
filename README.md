# gke
A repo for building and testing a google Kubernetes environment via Terraform and Pipelines.

## Goals

- [ ] Low Cost Playground GKE cluster deployed in to GCP.  
- [ ] Ability to deploy applications to GKE cluster via Helm charts. 
- [ ] Easily accessible and manage via local system (Makefile?).  

## Setup
```
export TF_VAR_project_id="project123456"
export TF_VAR_region="australia-southeast1"
export TF_VAR_cluster_zone="australia-southeast1-a"
export TF_VAR_cluster_name="playground"
```