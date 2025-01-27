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

## K3s

K3s is a lightweight version of Kubernetes that has the same role: _a container orchestration engine for automating deployment, scaling, and management of containerized applications_.

It's a fully conformant production-ready Kubernetes distribution that has been packaged a single binary, wraps Kubernetes and other components in a single launcher. Additionally, K3s simplify Kubernetes operations by maintaning functionnality for

- Managing the TLS certificates for Kubernetes components.
- Manageing the connection between worker and server nodes.
- Auto-deploying Kubernetes ressources from local manifests in realtime as they are changed.
- Managing an embedded etcd cluster ( a strongly consistent, distributed key-value store that is used by Kubernetes to store metadata information about the cluster objects).

The installation for this project is done via the provisionning script given to Vagrant.

|             |             |
| ----------- | ----------- |
| __SERVER__ | __AGENT__  |
| Manage the K8s API| Gather instructions from the server via the API |
| Manage the control plane, inlcuding the scheduler and the ressources| Execute the workload (pods & containers) |
| Manage the cluster's data | Share the data on their ressource |

This architecture has two big advantages : Easily scalable, since the addition of workload is distinct from the control plane; Resistant : one server can manage several agents, in case of a stopped agent, the serveur can reassign the workload to others.

### K3s commands

To verify K3s is running correctly after its installation, we use the script to check the status of the node, and after accessing the vm via the ssh command, we can run:

    systemctl status k3s

For more details, you can run the following command on the server machine:

    kubectl get nodes

## Kubectl

_kubectl_ is a command-line tool used to interact with Kubernetes cluster. It allows you to manage application running on Kubernetes, inspect cluster ressources, and perfom several administrative tasks.

### Kubectl commands

This command allows you to retrieve information about Kubernetes ressources.

    kubectl get

Is used to create resources from files or directly from command-line arguments.

    kubectl create

Similar to kubectl create, but it can also update existing resources.

    kubectl apply

Provides detailed information about a specific Kubernetes resource.

    kubectl describe

Fetches logs from a specific pod.

    kubectl logs

Executes a command inside a running container of a pod.

    kubectl exec

Deletes resources by name or from configuration files.

    kubectl delete

## The VM

Since the subject has to be done on a VM, we use VirtualBox Manager in order to create it. The VM is created on a Debian bookworm with a ssh port defined in the settings of the VM to be able to connect easily. You can also add the AdditionnalDisk if you want, but it's not necessary.

## Destroy the vm

Terminate the virtual machine without prompt.

    vagrant destroy -f

List the VM managed by Virtualbox.

    vboxmanage list vms

List the VM running and managed by Virtualbox.

    vboxmanage list runningvms

Take the control of the VM < VM NAME > to power it off.

    vboxmanage controlvm <VM NAME> poweroff

Delete the VM < VM NAME >.

    vboxmanage unregistervm <VM NAME> --delete

## Sources

[Vagrant official documentation](https://developer.hashicorp.com/vagrant)

[How to install VirtualBox Manager](https://linuxiac.com/how-to-install-virtualbox-on-debian-12-bookworm/)

[K3s official documentation](https://docs.k3s.io/)

[Kubernetes official documentation](https://kubernetes.io/docs/concepts/overview/#why-you-need-kubernetes-and-what-can-it-do)

[Stephane Robert sur Vagrant](https://blog.stephane-robert.info/docs/infra-as-code/provisionnement/vagrant/introduction/)

[Vagrantfile provider](https://portal.cloud.hashicorp.com/vagrant/discover/debian/bullseye64)

[Stephane Robert sur Kubectl](https://blog.stephane-robert.info/docs/conteneurs/orchestrateurs/outils/kubectl/)