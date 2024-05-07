GIT_REPO ?= $(shell basename `git rev-parse --show-toplevel`)
TF_ENV_VERSION = latest:^1.8.0
TF_DIRECTORY = terraform
TF_VARS_FILE = variables.tfvars

export

.PHONY: macos-requirements
macos-requirements:
	brew update
	brew install --cask google-cloud-sdk
	brew install kubernetes-cli infracost argocd tfenv checkov
	tfenv install ${TF_ENV_VERSION}
	tfenv use ${TF_ENV_VERSION}
	gcloud init
	gcloud components install gke-gcloud-auth-plugin

.PHONY: gcp.auth gcp.config infracost.auth auth infracost.breakdown
gcp.auth:
	gcloud auth application-default login

gcp.config:
	gcloud container clusters get-credentials ${TF_VAR_cluster_name} --zone ${TF_VAR_cluster_zone} --project ${TF_VAR_project_id}
	kubectl get all -A

infracost.auth:
	infracost auth login

auth: gcp.auth infracost.auth

infracost.breakdown:
	infracost breakdown --path ${TF_DIRECTORY}  --terraform-var-file ${TF_VARS_FILE} --show-skipped

.PHONY: tf.init tf.fmt tf.plan tf.apply tf.plan.destroy tf.apply.destroy
tf.init:
	@if [ "${TF_STATE_FILE_BUCKET}" = "" ]; then\
		echo "Using local backend.";\
		sed -i.bak '/backend "gcs" {}/s/^/#/' ${TF_DIRECTORY}/_providers.tf;\
		terraform -chdir=${TF_DIRECTORY} init;\
	else\
		echo "Using remote backend.";\
		sed -i.bak '/#backend "gcs" {}/s/^//' ${TF_DIRECTORY}/_providers.tf;\
		terraform -chdir=${TF_DIRECTORY} init\
			-backend-config="bucket=${TF_STATE_FILE_BUCKET}"\
			-backend-config="prefix=${GIT_REPO}";\
	fi 
	terraform -chdir=${TF_DIRECTORY} validate
	
tf.fmt:
	terraform -chdir=${TF_DIRECTORY} fmt --check --diff --recursive

tf.plan: tf.init tf.fmt infracost.breakdown
	rm -f terraform/tf.plan terraform/tf.plan.json
	terraform -chdir=${TF_DIRECTORY} plan -var-file=${TF_VARS_FILE} -out=tf.plan
	terraform -chdir=${TF_DIRECTORY} show -json tf.plan  > ${TF_DIRECTORY}/tf.plan.json
	# checkov -f ${TF_DIRECTORY}/tf.plan.json

tf.apply:
	terraform -chdir=${TF_DIRECTORY} apply tf.plan

tf.plan.destroy: tf.init
	rm -f terraform/tf.plan.destroy
	terraform -chdir=${TF_DIRECTORY} plan -var-file=${TF_VARS_FILE} -destroy -out=tf.plan.destroy

tf.apply.destroy:
	terraform -chdir=${TF_DIRECTORY} apply tf.plan.destroy

.PHONY: k.top argo.install argo.uninstall argo.info argo.portforward argo.password
k.top:
	kubectl top nodes
	kubectl top pods -A

argo.install:
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argo.uninstall:
	kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl delete namespace argocd

argo.info:
	kubectl get all -n argocd

argo.portforward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argo.password:
	argocd admin initial-password -n argocd
	argocd login 127.0.0.1:8080
	@echo "Please set a new admin password"
	argocd account update-password
