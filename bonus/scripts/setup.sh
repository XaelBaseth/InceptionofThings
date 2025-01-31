#!/bin/bash

set -e  # Exit on any error

# ===========================
# Constants and Configurations
# ===========================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
mkdir -p $HOME/logs
LOG_FILE="$HOME/logs/setup.log"

# GitHub and GitLab Details
GITHUB_REPO="https://github.com/XaelBaseth/42-IoT_acharlot"
GITLAB_DOMAIN="http://localhost:8081"
GITLAB_USERNAME="root"
GITLAB_PROJECT_NAME="IoT"

# ===========================
# Utility Functions
# ===========================

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local color

    case "$level" in
        INFO) color="$GREEN";;
        WARN) color="$YELLOW";;
        ERROR) color="$RED";;
        *) color="$BLUE";;
    esac

    echo -e "$timestamp ${color}[$level]${NC} $message" | tee -a "$LOG_FILE"
}

handle_error() {
    log ERROR "$1"
    exit 1
}

# ===========================
# Core Functions
# ===========================

create_cluster() {
    log INFO "Creating k3d clusters..."
    k3d cluster create argocd
    k3d cluster create dev
    k3d cluster create gitlab \
	--servers 1 --agents 2 \
	--memory 8GB

    kubectl create namespace dev
    kubectl create namespace argocd
    kubectl create namespace gitlab
}

install_argocd() {
    log INFO "Installing ArgoCD..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    log INFO "Waiting for ArgoCD to be ready..."
    sleep 60

    log INFO "Exposing ArgoCD UI..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
}

get_argocd_credentials() {
    log INFO "Retrieving ArgoCD credentials..."
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

    if [[ -z "$password" ]]; then
        handle_error "Failed to retrieve ArgoCD password."
    fi

    echo -e "${GREEN}ArgoCD admin username:${NC} admin"
    echo -e "${GREEN}ArgoCD admin password:${NC} $password"
    log INFO "You can now access ArgoCD at http://localhost:8080"
}

create_argocd_app() {
    log INFO "Creating ArgoCD application..."
    kubectl apply -n argocd -f ../confs/argocd.yaml
}

install_gitlab() {
    log INFO "Installing GitLab on k3d..."
    helm repo add gitlab https://charts.gitlab.io
    helm repo update

    helm upgrade --install gitlab gitlab/gitlab --namespace gitlab \
        --values confs/gitlab.yaml \
        --timeout 600s \

    log INFO "Waiting for GitLab to be deployed..."
    kubectl wait --for=condition=Ready --timeout=300s pod -l app=webservice -n gitlab

    log INFO "Port-forwarding GitLab to localhost:8081..."
    kubectl port-forward svc/gitlab-webservice-default 8081:80 --namespace gitlab &
}

generate_gitlab_token() {
    log INFO "Generating GitLab root access token..."
    GITLAB_POD=$(kubectl get pods -n gitlab -l app=webservice -o jsonpath="{.items[0].metadata.name}")

    if [ -z "$GITLAB_POD" ]; then
        handle_error "Failed to find GitLab pod."
    fi

    GITLAB_TOKEN=$(kubectl exec -it "$GITLAB_POD" -n gitlab -- bash -c "
        gitlab-rails runner \"token = User.find_by_username('root').personal_access_tokens.create(
            scopes: ['api', 'read_repository', 'write_repository'], 
            name: 'automation-token', 
            expires_at: 1.year.from_now
        ); 
        token.set_token('automation12345'); 
        token.save!; 
        puts token.token
        \"" | tail -n 1)

    if [[ -z "$GITLAB_TOKEN" ]]; then
        handle_error "Failed to generate GitLab token."
    fi

    log INFO "GitLab token generated successfully."
}

add_repo_to_gitlab() {
    log INFO "Cloning the GitHub repository..."
    git clone "$GITHUB_REPO" || handle_error "Failed to clone the repository."
    cd YOUR-REPO

    log INFO "Creating GitLab project via API..."
    curl --header "PRIVATE-TOKEN: automation12345" -X POST "$GITLAB_DOMAIN/api/v4/projects" \
        --data "name=$GITLAB_PROJECT_NAME" \
        --data "visibility=public" || handle_error "Failed to create project in GitLab."

    log INFO "Adding GitLab remote and pushing repository..."
    git remote add gitlab "$GITLAB_DOMAIN/$GITLAB_USERNAME/$GITLAB_PROJECT_NAME.git"
    git push --mirror gitlab || handle_error "Failed to push to GitLab."

    log INFO "Repository successfully added to GitLab."
}

get_gitlab_credentials() {
    log INFO "Retrieving GitLab root password..."
    password=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)

    if [[ -z "$password" ]]; then
        handle_error "Failed to retrieve GitLab password."
    fi

    echo -e "${GREEN}GitLab admin username:${NC} root"
    echo -e "${GREEN}GitLab admin password:${NC} $password"
    log INFO "You can now access GitLab at http://localhost:8081"
}

# ===========================
# Main Script Execution
# ===========================

log INFO "Creating the cluster..."
create_cluster

log INFO "Setting up ArgoCD..."
install_argocd

log INFO "Retrieving ArgoCD login credentials..."
get_argocd_credentials

log INFO "Creating ArgoCD application..."
create_argocd_app

log INFO "Setting up GitLab..."
install_gitlab

log INFO "Retrieving GitLab login credentials..."
get_gitlab_credentials

# log INFO "Generating GitLab root token..."
# generate_gitlab_token
# 
# log INFO "Adding GitHub repository to GitLab..."
# add_repo_to_gitlab

log INFO "Setup completed successfully!"
