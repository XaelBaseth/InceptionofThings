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
LOG_FILE="$HOME/logs/install.log"

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

run_as_sudo() {
	if [ "$EUID" -ne 0 ]; then
		log ERROR "Please run this script with sudo."
		exit 1
	fi
}

# Install Docker
install_docker() {
    if ! command -v docker &>/dev/null; then
        log INFO "Installing Docker..."
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        log INFO "Docker installed successfully."
    else
        log INFO "Docker is already installed."
    fi
}

set_docker() {
    if ! groups $USER | grep -qw docker; then
        sudo groupadd docker || true 
        sudo usermod -aG docker $USER
        log INFO "User added to Docker group. A reboot might be required."
    else
        log INFO "User already in the Docker group."
    fi
}

# Install k3d
install_k3d() {
    if ! command -v k3d &>/dev/null; then
        log INFO "Installing k3d..."
        curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
        command -v k3d &>/dev/null || handle_error "k3d installation failed."
        log INFO "k3d installed successfully."
    else
        log INFO "k3d is already installed."
    fi
}

install_kubectl() {
    if ! command -v kubectl &>/dev/null; then
        log INFO "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
        command -v kubectl &>/dev/null || handle_error "kubectl installation failed."
        log INFO "kubectl installed successfully."
    else
        log INFO "kubectl is already installed."
    fi
}

# ===========================
# Main Script Execution
# ===========================

run_as_sudo

log INFO "Starting setup for the p3 Inception of Things..."
install_docker
set_docker
install_kubectl
install_k3d

log INFO "Setup complete! Please reboot your system for group changes to take effect."
