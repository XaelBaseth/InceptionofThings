# INCEPTION OF THINGS

This project aims to deepen your knowledge by making you use K3d and K3s with Vagrant. You will start with Vagrant, then K3s and its Ingress, and finally K3d. These steps will get you started with Kubernetes.

A virtual machine is needed for this project.

## Vagrant

Vagrant is an Hashicorp tool that is __"designed for everyone as the simplest and fastest way to create a virtualized environment"__. It provides a consistent and portable development environment for developers and teams, ensuring that software works the same way across different systems. Machines are provisioned on top of VirtualBox, VMWare, AWS, etc. Then you can use provisioning tools to automatically install and configure software on the VM.

### Vagrant vs Docker

|             |             |
| ----------- | ----------- |
| **Vagrant** | **Docker**  |
| VM Management Tool | Containerization Platform |
| Heavy on ressources | Light on ressources |
| Used for development environments to mimic production systems | Used for microservices and CI/CD pipelines |
| Portable but require the same virtualization provider | Portable on any system with Docker installed |

Use Vagrant for running multiple virtual machines, and Docker for a scalable environments for applications or microservices.

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

    vboxmanage list running vms

Take the control of the VM <VM NAME> to power it off.

    vboxmanage controlvm <VM NAME> poweroff

Delete the VM <VM NAME>.

    vboxmanage unregistervm <VM NAME> --delete
