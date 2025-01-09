# INCEPTION OF THINGS

This project aims to deepen your knowledge by making you use K3d and K3s with Vagrant. You will start with Vagrant, then K3s and its Ingress, and finally K3d. These steps will get you started with Kubernetes.

A virtual machine is needed for this project.

## Vagrant

Vagrant is an Hashicorp tool that is __"designed for everyone as the simplest and fastest way to create a virtualized environment"__. It provides a consistent and portable development environment for developers and teams, ensuring that software works the same way across different systems. Machines are provisioned on top of VirtualBox, VMWare, AWS, etc. Then you can use provisioning tools to automatically install and configure software on the VM.

### Vagrant vs Docker

|             |             |
| ----------- | ----------- |
| __Vagrant__ | __Docker__  |
| VM Management Tool | Containerization Platform |
| Heavy on ressources | Light on ressources |
| Used for development environments to mimic production systems | Used for microservices and CI/CD pipelines |
| Portable but require the same virtualization provider | Portable on any system with Docker installed |

Use Vagrant for running multiple virtual machines, and Docker for a scalable environments for applications or microservices.

### Install Vagrant on the VM

    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install vagrant

Vagrant needs a provisionner to run. For easier use, we install Oracle VirtualBox Manager with the following commands.

    wget -O- -q https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmour -o /usr/share/keyrings/oracle_vbox_2016.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sudo apt update && sudo apt install virtualbox-7.1

### Vagrant commands

    vagrant init

Initialize the Vagrantfile.

    vagrant up

Start the virtual machine.

    vagrant ssh <VM NAME>

Connect to the VM with ssh.

    vagrant destroy

Terminate the virtual machine.

## Destroy the vm

Terminate the virtual machine without prompt.

    vagrant destroy -f

List the VM managed by Virtualbox.

    vboxmanage list vms

List the VM running and managed by Virtualbox.

    vboxmanage list runningvms

Take the control of the VM <VM NAME> to power it off.

    vboxmanage controlvm <VM NAME> poweroff

Delete the VM <VM NAME>.

    vboxmanage unregistervm <VM NAME> --delete

## The VM

Since the subject has to be done on a VM, we use VirtualBox Manager in order to create it. The VM is created on a Debian bookworm with a ssh port defined in the settings of the VM to be able to connect easily. You can also add the AdditionnalDisk if you want, but it's not necessary.

## Sources

[Vagrant official documentation](https://developer.hashicorp.com/vagrant)

[How to install VirtualBox Manager](https://linuxiac.com/how-to-install-virtualbox-on-debian-12-bookworm/)
