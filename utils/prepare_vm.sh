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
LOG_FILE="$HOME/logs/prepare_vm.log"

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

# Install basic dependencies
install_service() {
    log INFO "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    log INFO "Installing basic dependencies..."
    if ! dpkg -l | grep -qw curl || ! dpkg -l | grep -qw gpg || ! dpkg -l | grep -qw build-essential || ! dpkg -l | grep -qw ca-certificates; then
        sudo apt install -y curl gpg build-essential ca-certificates
        log INFO "Basic dependencies installed successfully."
    else
        log INFO "Basic dependencies already installed."
    fi
}

# Install Vagrant
install_vagrant() {
    if ! command -v vagrant &>/dev/null; then
        log INFO "Installing Vagrant..."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y vagrant
        log INFO "Vagrant installed successfully."
    else
        log INFO "Vagrant is already installed."
    fi
}

# Install Virtualbox Manager and dependencies
install_vboxManager() {
    if ! command -v virtualbox &>/dev/null; then
        log INFO "Installing VirtualBox..."
        wget -O- -q https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmour -o /usr/share/keyrings/oracle_vbox_2016.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
        sudo apt update && sudo apt install virtualbox-7.1 -y
        log INFO "VirtualBox installed successfully."
    else
        log INFO "VirtualBox is already installed."
    fi
}

# ===========================
# Main Script Execution
# ===========================

run_as_sudo

log INFO "Starting setup for Inception of Things..."
install_service
install_vagrant
install_vboxManager

log INFO "Setup the IP adresses in the /etc/hosts"
echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════╗"
echo "║         P1 & P2 Setup Complete	      ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

log INFO "Setup complete! Please reboot your system for group changes to take effect."
