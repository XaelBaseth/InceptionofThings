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
LOG_FILE="/vagrant/logs/agent-install.log"
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"  # Ensure the log directory exists

# Retry configuration
MAX_ATTEMPTS=10
RETRY_INTERVAL=5

# SSH Configuration
SERVER_IP="192.168.56.110"
SSH_OPTS="-o ConnectTimeout=5 \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -i /vagrant/.vagrant/machines/abdeel-oS/virtualbox/private_key"

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

verify_ssh_connection() {
    run_with_retry \
        "ssh $SSH_OPTS vagrant@$SERVER_IP exit" \
        "Verifying SSH connection to $SERVER_IP"
}

retrieve_node_token() {
    log INFO "Retrieving node token from server..."
    NODE_TOKEN=$(ssh $SSH_OPTS vagrant@$SERVER_IP \
        "sudo cat /var/lib/rancher/k3s/server/node-token") || handle_error "Failed to retrieve node token"
    log INFO "Node token retrieved successfully"
}

install_k3s_agent() {
    log INFO "Installing K3s agent..."
    curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${NODE_TOKEN}" \
    sh - || handle_error "Failed to install K3s agent"
    log INFO "K3s agent installed successfully"
}

wait_for_service() {
    local service_name="$1"
    run_with_retry \
        "systemctl is-active --quiet $service_name" \
        "Waiting for $service_name to start"
}

# ===========================
# Main Script
# ===========================

trap 'handle_error "Unexpected error occurred. Exiting..."' ERR

log INFO "Starting K3s agent setup..."
log INFO "Waiting for server to be fully initialized..."
sleep 30  # Optional delay to ensure server readiness

# Verify SSH connection
verify_ssh_connection

# Retrieve the K3s node token
retrieve_node_token

# Install the K3s agent
install_k3s_agent

# Wait for K3s agent service to start
wait_for_service k3s-agent || handle_error "K3s agent service failed to start"

# Print success message
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════╗"
echo "║         K3s Agent Setup Complete      ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

log INFO "K3s agent setup complete! 🚀"
