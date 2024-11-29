#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'


MAX_ATTEMPS=10
RETRY_INTERVAL=5

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
	print_status "$service is ready."
	return 0
}

verify_node() {
	local attempt=1

	print_status "Verifying node status..."
	while ! kubectl get nodes | grep -q "Ready"; do
		if [ $attempt -ge $MAX_ATTEMPS ]; then
			return 1
		fi
		print_warning "Attempt $attemp/$MAX_ATTEMPS..."
		sleep $RETRY_INTERVAL
		((attemp++))
	done
	print_status "Node is ready."
	return 0
}

print_banner() {
	echo -e "${GREEN}"
	echo -e "K3s server installation"
	echo -e "${RESET}"
}

setup_kubeconfig() {
	print_status "Setting up kubeconfig permissions..."
	sudo mkdir -p /home/vagrant/.kube
	sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
	sudo chown -R vagrant:vagrant /home/vragrant/.kube
	sudo chmod 600 /home/vagrant/.kube/config
	print_status "Kubeconfig permissions updated."
}

print_banner

print_status "Installing K3s server..."
curl -sfL https://get.k3s.io | \
       INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" \
       sh - || handle_error "Failed to install K3s"
print_status "K3s installed successfully."

wait_for_service k3s || \
	handle_error "K3s service faile to start."

print_status "Checking kubectl installation..."
command -v kubectl >/dev/null 2>&1 || \
	handle_error "kubectl not installed"
print_status "kubectl is available."

verify_node || handle_error "Node failed to become ready."

print_status "Configuring node token permission..."
sudo chmod 644 /var/lib/rancher/k3s/server/node-token
print_status "Token permission updated."

setup_kubeconfig

echo -e "${GREEN}"
echo -e "K3s Server Setup Complete !"
echo -e "${RESET}"

print_status "Current node status: "
kubectl get nodes
	
