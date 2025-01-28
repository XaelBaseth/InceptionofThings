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
	sudo apt install -y curl gpg build-essential
}

# Install Vagrant
install_vagrant() {
    log INFO "Installing Vagrant..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y vagrant
	vagrant plugin install vagrant-libvirt

    command -v vagrant >/dev/null 2>&1 || handle_error "Vagrant installation failed."
    log INFO "Vagrant installed successfully."
}

# Install Virtualbox Manager and dependencies
install_vboxManager() {
	wget -O- -q https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmour -o /usr/share/keyrings/oracle_vbox_2016.gpg
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
	sudo apt update && sudo apt install virtualbox-7.1 -y

	command -v virtualbox >/dev/null 2>&1 || handle_error "VirtualBox installation failed."
	log INFO "VirtualBox installed successfully."
}


# ===========================
# Main Script Execution
# ===========================

run_as_sudo

log INFO "Starting setup for Vagrant with Vbox Manager..."
install_service
install_vagrant
install_vboxManager

log INFO "Setup complete! Please reboot your system for group changes to take effect."
