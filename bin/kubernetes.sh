#!/bin/sh

kube_config()
{
    echo "Setting up kube config..."
    gcloud container clusters get-credentials ${TF_VAR_cluster_name} --zone ${TF_VAR_cluster_zone} --project ${TF_VAR_project_id}
    kubectl version
}

argo_install()
{
    kubectl create namespace argocd -o yaml --dry-run=client | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    sleep 10
    kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
    port_pid=$!
    echo $port_pid
    trap cleanup INT TERM
    argocd admin initial-password -n argocd
	argocd login 127.0.0.1:8080
	echo "Please set a new admin password..."
	argocd account update-password
    exit
}

argo_uninstall()
{
    kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl delete namespace argocd
}

cleanup()
{
    echo "Cleaning up old processes..."
    kill $port_pid
    exit
}