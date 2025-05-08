# Home Lab Infrastructure

This repository contains the infrastructure and applications used in my home lab/sandbox for DevOps, although this is all still being elaborated upon on the daily.

This guide will describe how to create a clean, reusable Ubuntu 24.04 VM template in Proxmox, ready for automated provisioning 

## Stack Overview

- **Docker Host**: Ubuntu VM running all services via Docker Compose
	- **Jenkins**: CI/CD pipelines
	- **Nexus**: Docker image registry
	- **Portainer**: Docker GUI management
- **Ansible**: Ubuntu VM for infrastructure automation
	- **Terraform**: Infrastructure deployment
- **Pi-hole**: RPi 4/4GB DNS-based ad-blocker 
	- **VaultWarden**: Home-based vault
- **Monitoring**: Ubuntu VM for monitoring
	- **Zabbix**: 
	- **ELK**: 

## Repo Layout

    home-lab/
    ├── ansible/
    ├── terraform/
    ├── docker-apps/
    ├── monitoring/
    ├── devops-stack/
    ├── scripts/
    │   └── template-bootstrap.sh
    └── README.md


## Getting Started

The assumption here is that you will have a basic Proxmox install on your hypervisor. From there your first point of call would be to upload an Ubuntu 24.04+ ISO into Proxmox and create a very basic VM.
Once that is done, the scripts will take care of the rest of the setup, including post-deployment configuration and templating. 

### 1. Prerequisites

- Ubuntu 24.04+ VM with SSH access
- SSH access to Ansible host
- A working Proxmox VE installation.
- CRITCAL: VM is not yet configured as a template.


### 2. Setup Steps (One-Time for Templating)

- SSH into the base VM:
    ssh ubuntu@<VM-IP>

- Run the bootstrap script:
  - Fetch and run from Git:
      curl -s https://raw.githubusercontent.com/karwowskii/home-lab/main/scripts/template-bootstrap.sh | bash
  - What this script does:
      - Updates and installs required packages:
          cloud-init, qemu-guest-agent, net-tools, etc.
      - Configures netplan for DHCP via cloud-init
      - Enables cloud-init and qemu-guest-agent
      - Cleans out system-specific IDs and SSH keys
      - Powers off the machine

- In Proxmox:
  - Convert the VM to a template:
      qm template <VMID>

- Now this template is ready to clone.

### 3. Next Steps

Use Ansible or Terraform to automate cloning and provisioning

Create VMs like docker-ubuntu, ansible-node, k3s-master, logging-ubuntu from this base

Store all scripts, Ansible roles, and Terraform modules in your home-lab repo


