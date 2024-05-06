tf-directory=terraform
tf-vars-file=variables.tfvars

export

macos-requirements:
	brew update
	brew install --cask google-cloud-sdk
	brew tap hashicorp/tap && brew install hashicorp/tap/terraform
	brew install kubernetes-cli infracost argocd
	gcloud init
	gcloud components install gke-gcloud-auth-plugin

gcp.auth:
	gcloud auth application-default login

gcp.config:
	gcloud container clusters get-credentials ${TF_VAR_cluster_name} --zone ${TF_VAR_cluster_zone} --project ${TF_VAR_project_id}
	kubectl get all -A

infracost.auth:
	infracost auth login

auth: gcp.auth infracost.auth

infracost.breakdown:
	infracost breakdown --path ${tf-directory}  --terraform-var-file ${tf-vars-file} --show-skipped

tf.init:
	terraform -chdir=${tf-directory} init
	terraform -chdir=${tf-directory} validate
	terraform -chdir=${tf-directory} fmt

tf.plan: tf.init infracost.breakdown
	rm -f terraform/tf.plan terraform/tf.plan.json
	terraform -chdir=${tf-directory} plan -var-file=${tf-vars-file} -out=tf.plan
	terraform -chdir=${tf-directory} show -json tf.plan  > ${tf-directory}/tf.plan.json
	# checkov -f ${tf-directory}/tf.plan.json

tf.apply:
	terraform -chdir=${tf-directory} apply tf.plan

tf.plan.destroy: tf.init
	rm -f terraform/tf.plan.destroy
	terraform -chdir=${tf-directory} plan -var-file=${tf-vars-file} -destroy -out=tf.plan.destroy

tf.apply.destroy:
	terraform -chdir=${tf-directory} apply tf.plan.destroy

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
