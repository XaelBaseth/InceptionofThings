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
LOG_FILE="/vagrant/logs/server-install.log"
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"  # Ensure the log directory exists

# Retry configuration
MAX_ATTEMPTS=12
RETRY_INTERVAL=5

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

run_with_retry() {
    local command="$1"
    local description="$2"
    local attempt=1

    log INFO "Starting: $description"
    while ! eval "$command"; do
        if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
            log ERROR "Failed: $description after $MAX_ATTEMPTS attempts"
            return 1
        fi
        log WARN "Attempt $attempt/$MAX_ATTEMPTS failed. Retrying in $RETRY_INTERVAL seconds..."
        sleep "$RETRY_INTERVAL"
        ((attempt++))
    done
    log INFO "Success: $description"
    return 0
}

# ===========================
# Core Functions
# ===========================

setup_kubeconfig() {
    log INFO "Setting up kubeconfig permissions..."
    sudo mkdir -p /home/vagrant/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
    sudo chown -R vagrant:vagrant /home/vagrant/.kube
    sudo chmod 600 /home/vagrant/.kube/config
    log INFO "Kubeconfig permissions updated"
}

install_k3s() {
    log INFO "Installing K3s server..."
    curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" \
    sh - || handle_error "Failed to install K3s"
}

wait_for_service() {
    local service_name="$1"
    run_with_retry \
        "systemctl is-active --quiet $service_name" \
        "Waiting for $service_name to start"
}

verify_node() {
    run_with_retry \
        "kubectl get nodes | grep -q 'Ready'" \
        "Waiting for Kubernetes node to become Ready"
}

# ===========================
# Main Script
# ===========================

trap 'handle_error "Unexpected error occurred. Exiting..."' ERR

log INFO "Starting K3s server setup..."
install_k3s

wait_for_service k3s || handle_error "K3s service failed to start"
log INFO "K3s service is running"

log INFO "Checking kubectl installation..."
command -v kubectl >/dev/null 2>&1 || handle_error "kubectl not installed"
log INFO "kubectl is available"

verify_node || handle_error "Node failed to become ready"
log INFO "Node is ready"

log INFO "Configuring node token permissions..."
sudo chmod 644 /var/lib/rancher/k3s/server/node-token
log INFO "Token permissions updated"

setup_kubeconfig

log INFO "K3s server setup complete! 🚀"
kubectl get nodes | tee -a "$LOG_FILE"
