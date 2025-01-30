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
	k3d cluster create argocd
	k3d cluster create dev
}

install_argocd() {
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	log INFO "Exposing ArgoCD UI"
	kubectl port-forward svc/argocd-server -n argocd 8080:443 &
	log INFO "Waiting for ArgoCD to be ready"
	sleep 60
}

get_argocd_credentials() {
    log INFO "Retrieving ArgoCD credentials..."

    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d) 
    if [[ -z "$password" ]]; then
        log ERROR "Failed to retrieve ArgoCD password."
        exit 1
    fi
    echo -e "${GREEN}ArgoCD admin username:${NC} admin"
    echo -e "${GREEN}ArgoCD admin password:${NC} $password"

    log INFO "You can now access ArgoCD at http://localhost:8080"
}

create_argocd_app() {
	kubectl apply -n argocd -f ../confs/argocd.yaml
	log INFO "ArgoCD application created for 42-IoT_acharlot"
}

# ===========================
# Main Script Execution
# ===========================

log INFO "Creating the cluster"
create_cluster

log INFO "Setting up Argo CD"
install_argocd

log INFO "Retrieving ArgoCD login credentials"
get_argocd_credentials

log INFO "Creating ArgoCD application to deploy from GitHub"
create_argocd_app

log INFO "Making sure that ArgoCD is running..."
kubectl get pods -n argocd

kubectl port-forward svc/argocd-server -n argocd 8080:443
