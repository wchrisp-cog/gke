tf-directory=terraform
tf-vars-file=variables.tfvars

export

macos-requirements:
	brew update
	brew install --cask google-cloud-sdk
	brew tap hashicorp/tap && brew install hashicorp/tap/terraform
	brew install kubernetes-cli infracost
	gcloud init
	gcloud components install gke-gcloud-auth-plugin

gcp.auth:
	gcloud auth application-default login

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
	rm -f terraform/tfplan
	terraform -chdir=${tf-directory} plan -var-file=${tf-vars-file} -out=tfplan

tf.apply:
	terraform -chdir=${tf-directory} apply tfplan

tf.plan.destroy: tf.init
	rm -f terraform/tfplan.destroy
	terraform -chdir=${tf-directory} plan -var-file=${tf-vars-file} -destroy -out=tfplan.destroy

tf.apply.destroy:
	terraform -chdir=${tf-directory} apply tfplan.destroy

k.creds:
	gcloud container clusters get-credentials ${TF_VAR_cluster_name} --zone ${TF_VAR_cluster_zone} --project ${TF_VAR_project_id}
	kubectl get all -A