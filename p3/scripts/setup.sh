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
	k3d cluster create argo-cd
	k3d cluster create dev
}

install_argocd() {
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	log INFO "Exposing ArgoCD UI"
	kubectl port-forward svc/argocd-server -n argocd 8080:443 &
	log INFO "Waiting for ArgoCD to be ready"
}



# ===========================
# Main Script Execution
# ===========================
