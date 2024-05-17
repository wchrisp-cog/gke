#!/bin/sh
. bin/terraform.sh
. bin/kubernetes.sh
. .env

main()
{
    terraform_init
    if [ "$1" = "destroy" ]; then
        terraform_plan_destroy
        terraform_apply
    elif [ "$1" = "build" ]; then
    	infracost breakdown --path ${TF_DIRECTORY}  --terraform-var-file ${TF_VARS_FILE} --show-skipped
        terraform_plan
        terraform_apply
        kube_config
        argo_install
    else
        echo "Please specify the argument build or destroy..."
        exit 1
    fi
}

main "$1"