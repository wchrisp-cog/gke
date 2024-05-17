#!/bin/sh
GIT_REPO=$(basename "$(git rev-parse --show-toplevel)")
TF_DIRECTORY="terraform"
TF_VARS_FILE="variables.tfvars"

terraform_init()
{
    if [ "${TF_STATE_FILE_BUCKET}" = "" ]; then
		echo "Using local backend."
		sed -i.bak 's/ backend "gcs" {}/#backend "gcs" {}/g' ${TF_DIRECTORY}/_providers.tf
		terraform -chdir=${TF_DIRECTORY} init
	else
		echo "Using remote backend."
		sed -i.bak 's/#backend "gcs" {}/ backend "gcs" {}/g' ${TF_DIRECTORY}/_providers.tf
		terraform -chdir=${TF_DIRECTORY} init \
			-backend-config="bucket=${TF_STATE_FILE_BUCKET}" \
			-backend-config="prefix=${GIT_REPO}"
	fi 
	terraform -chdir=${TF_DIRECTORY} validate
	terraform -chdir=${TF_DIRECTORY} fmt --check --diff --recursive
}

terraform_plan()
{
	rm -f terraform/tf.plan terraform/tf.plan.json
	terraform -chdir=${TF_DIRECTORY} plan -var-file=${TF_VARS_FILE} -out=tf.plan
	terraform -chdir=${TF_DIRECTORY} show -json tf.plan  > ${TF_DIRECTORY}/tf.plan.json
	# checkov -f ${TF_DIRECTORY}/tf.plan.json
	echo "Press enter to continue..."
	read -r
}

terraform_plan_destroy()
{
	rm -f terraform/tf.plan terraform/tf.plan.json
	terraform -chdir=${TF_DIRECTORY} plan -var-file=${TF_VARS_FILE} -destroy -out=tf.plan
	echo "Press enter to continue..."
	read -r
}

terraform_apply()
{
	terraform -chdir=${TF_DIRECTORY} apply tf.plan
}