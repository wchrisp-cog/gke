#!/bin/sh
BREW_CASKS="google-cloud-sdk"
BREW_PKGS="kubernetes-cli infracost argocd tfenv checkov dotenvx/brew/dotenvx"

envs()
{
    echo "Setting up environment variables..."
    cp .env.example .env
}

requirements()
{
    echo "Installing Requirements..."
    brew update
	brew install --cask ${BREW_CASKS}
	brew install ${BREW_PKGS}
	tfenv install
	tfenv use
	gcloud init
	gcloud components install gke-gcloud-auth-plugin
}

auth()
{
    echo "Setting up authentication"
    gcloud auth application-default login
    infracost auth login
}

main()
{
    echo "Configuring your environment..."
    requirements
    envs
    auth
    echo "Configuration complete..."
}

main