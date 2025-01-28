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

## Kubernetes

Kubernetes is an open-source platform for automating the deployment, scaling, and management of containerized applications. It provides a framework to run distributed systems reliably and efficiently. Kubernetes abstracts the underlying infrastructure (whether it's on-premises or cloud-based) and offers key functionalities like:

1. Container Orchestration: It automatically schedules and deploys containers across a cluster of machines, optimizing resource usage.

2. Scaling: Kubernetes can scale applications up or down based on demand, ensuring optimal performance and resource efficiency.

3. Service Discovery and Load Balancing: It provides mechanisms for exposing applications to external traffic, distributing requests across containers, and maintaining high availability.

4. Self-Healing: Kubernetes monitors the health of containers and replaces or restarts failed ones automatically.

5. Configuration Management: You can define the desired state of your application (e.g., the number of replicas, container configurations) declaratively using YAML or JSON files. Kubernetes ensures the system aligns with this state.

6. Rolling Updates and Rollbacks: It allows you to update applications incrementally, reducing downtime. If something goes wrong, Kubernetes can revert to a previous version.

By simplifying the management of containerized workloads and offering robust tools for reliability and scalability, Kubernetes has become a cornerstone for modern cloud-native application development.

### K3s

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
| Manage the control plane, including the scheduler and the ressources| Execute the workload (pods & containers) |
| Manage the cluster's data | Share the data on their ressource |

This architecture has two big advantages : Easily scalable, since the addition of workload is distinct from the control plane; Resistant : one server can manage several agents, in case of a stopped agent, the serveur can reassign the workload to others.

### Ingress

An ingress is a Kubernetes resource that manages external access to services within a cluster, mostly HTTP or HTTPS traffic. It acts as a reverse proxy, routing requests to the appropriate service based on defined rules like URL paths or hostnames. It allows for __centralized management__ of traffic routing, often including features like load balancing, and access control.

### Kubectl

_kubectl_ is a command-line tool used to interact with Kubernetes cluster. It allows you to manage application running on Kubernetes, inspect cluster ressources, and perfom several administrative tasks.

#### Kubectl commands

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

Destroy the box

    vagrant box remove <box_name>

List the VM managed by Virtualbox.

    vboxmanage list vms

List the VM running and managed by Virtualbox.

    vboxmanage list runningvms

Take the control of the VM < VM NAME > to power it off.

    vboxmanage controlvm <VM NAME> poweroff

Delete the VM < VM NAME >.

    vboxmanage unregistervm <VM NAME> --delete

Delete the `.vagrant/` folder

    rm -rf .vagrant/

You can finally clean the system

    sudo apt-get autoremove -y && sudo apt-get clean

## Sources

[Vagrant official documentation](https://developer.hashicorp.com/vagrant)

[How to install VirtualBox Manager](https://linuxiac.com/how-to-install-virtualbox-on-debian-12-bookworm/)

[K3s official documentation](https://docs.k3s.io/)

[Kubernetes official documentation](https://kubernetes.io/docs/concepts/overview/#why-you-need-kubernetes-and-what-can-it-do)

[Stephane Robert sur Vagrant](https://blog.stephane-robert.info/docs/infra-as-code/provisionnement/vagrant/introduction/)

[Vagrantfile provider](https://portal.cloud.hashicorp.com/vagrant/discover/debian/bullseye64)

[Stephane Robert sur Kubectl](https://blog.stephane-robert.info/docs/conteneurs/orchestrateurs/outils/kubectl/)

[Ingress official documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

[P2 Web app image](https://github.com/paulbouwer/hello-kubernetes)

[]()

[]()
