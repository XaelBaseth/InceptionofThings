#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

SERVER_IP="192.168.56.110"
MAX_ATTEMPTS=10
RETRY_INTERVAL=5
SSH_OPTS="-o ConnectTimeout=5 \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -i /vagrant/.vagrant/machines/abdeel-oS/virtualbox/private_key"

log() {
	local timestamp="+%Y-%M-%D %H:%M:%S"

	case "$1" in
		INFO)
		       	echo -e "$timestamp ${GREEN}  $2 ${RESET}" | tee -a /vagrant/logs/server_install.log
			;;
		WARN)
			echo -e "$timestamp ${YELLOW} $2 ${RESET}" | tee -a /vagrant/logs/server_install.log
			;;
		ERROR)
			echo -e "$timestamp ${RED} $2 ${RESET}" | tee -a /vagrant/logs/server_install.log
			;;
		*)
			echo -e "$timestamp ${BLUE} $2 ${RESET}" | tee -a /vagrant/logs/server_install.log
			;;
	esac	
}

handle_error() {
	log ERROR "$1"
	exit 1
}

print_status() {
	log INFO "$1"
}

print_warning() {
	log "[WARNING]: $1"
}

verify_ssh() {
    local ip=$1
    local attempt=1

    print_status "Verifying SSH connection to $ip..."
    while ! ssh $SSH_OPTS vagrant@${ip} "exit" >/dev/null 2>&1; do
        if [ $attempt -ge $MAX_ATTEMPTS ]; then
            return 1
        fi
        print_warning "Attempt $attempt/$MAX_ATTEMPTS - Waiting for SSH..."
        sleep $RETRY_INTERVAL
        ((attempt++))
    done
    print_success "SSH connection established"
    return 0
}

wait_for_service() {
    local service=$1
    local attempt=1
    
    print_status "Waiting for $service to start..."
    while ! systemctl is-active --quiet $service; do
        if [ $attempt -ge $MAX_ATTEMPTS ]; then
            return 1
        fi
        print_warning "Attempt $attempt/$MAX_ATTEMPTS..."
        sleep $RETRY_INTERVAL
        ((attempt++))
    done
    print_success "$service is running"
    return 0
}

print_banner() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║         K3s Agent Installation        ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_status "Waiting for server to be fully initialized..."
sleep 30

print_banner

verify_ssh $SERVER_IP || handle_error "Cannot establish SSH connection to server"

print_status "Retrieving node token from server..."
NODE_TOKEN=$(ssh $SSH_OPTS vagrant@${SERVER_IP} \
    "sudo cat /var/lib/rancher/k3s/server/node-token") || \
    handle_error "Failed to retrieve node token"
print_success "Node token retrieved"

print_status "Installing K3s agent..."
curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${NODE_TOKEN}" \
    sh - || handle_error "Failed to install K3s agent"
print_success "K3s agent installed"

wait_for_service k3s-agent || handle_error "K3s agent service failed to start"

echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║         K3s Agent Complete	          ║"
    echo "╚═══════════════════════════════════════╝"
echo -e "${RESET}"

print_status "Agent node is now connected to the cluster"
