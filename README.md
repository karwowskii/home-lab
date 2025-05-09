# Home Lab Infrastructure

This repository contains the infrastructure and applications used in my home lab/sandbox for DevOps, although this is all still being elaborated upon on the daily.

This guide will describe how to create a clean, reusable Ubuntu 24.04 VM template in Proxmox, ready for automated provisioning 

## Stack Overview

This home lab consists of:

   - Orchestration VM (ansible-node):
       * Runs Ansible and Terraform
       * Provisions all other VMs
   - Docker Host (docker-ubuntu):
       * Jenkins (CI/CD)
       * Nexus (Docker registry)
       * Portainer (container management)
   - Monitoring VM (monitoring):
       * Prometheus + Grafana (metrics stack)
   - K3s Cluster Master (k3s-master):
       * Lightweight Kubernetes for experimentation

Additional services like Pi-hole and Vaultwarden may run on physical Raspberry Pis and are referenced but not provisioned by this repository.

## Repo structure

	home-lab/
	├── 00-proxmox-template/         # Optional legacy template setup
	├── 01-scripts/                  # Core bootstrap scripts
	│   ├── create-ansible-node.sh   # Main provisioning entry point
	│   └── setup.sh                 # Bootstrap entry point from clean Proxmox
	├── ansible/                     # Infrastructure automation
	│   ├── playbooks/
	│   └── roles/
	├── devops-stack/                # Docker Compose services (Jenkins, Nexus, etc.)
	├── docker-apps/                 # Sample Jenkins apps
	├── terraform/                   # Infra-as-code (under development)
	├── docs/                        # Diagrams, setup guides
	└── README.md

## Quick Start (Proxmox Host)

Assumes a clean Proxmox VE install with network access and no templates configured.

## 1. Download and Run Setup

SSH into the Proxmox node and run:
	wget https://raw.githubusercontent.com/karwowskii/home-lab/main/01-scripts/setup.sh
	chmod +x setup.sh
	./setup.sh

This script:
   * Installs required tools (wget, jq, cloud-image-utils, etc.)
   * Downloads and runs the create-ansible-node.sh script
   * Bootstraps the ansible-node VM using Ubuntu 24.04 cloud image

## 2. SSH into Control Node

Once created, SSH into the ansible-node using the discovered IP (auto-printed by the script):
	ssh ubuntu@<ansible-node-ip>

## 3. Continue Provisioning

From within the control node:
   * Use Ansible to provision remaining VMs
   * Use Terraform to optionally define VM infrastructure
   * Deploy Docker-based services with Compose

Automation playbooks will be stored in ansible/playbooks/.

## Bootstrap from a Clean Proxmox Installation

If you're working from a fresh Proxmox VE install, and no templates or Git are available, this project can still be used to fully automate your environment.

#### Step-by-Step Bootstrap Instructions

    1. SSH into your Proxmox host and run the following:
	wget https://raw.githubusercontent.com/karwowskii/home-lab/main/01-scripts/setup.sh
	chmod +x setup.sh
	./setup.sh

    This script will:
    * Install required packages (wget, jq, cloud-image-utils, etc.)
    * Download and execute create-ansible-node.sh
    * Provision the control node (ansible-node) using Ubuntu 24.04 cloud-init image

    2. SSH into the new orchestration VM:
	ssh ubuntu@<ansible-node-ip>

    This IP will be shown at the end of the script output.

    3. Continue provisioning from inside the control node using Ansible and Terraform.

## Next Steps and Automation Plan

    * Use Ansible playbooks (ansible/playbooks/) to configure:
       * Docker host (Jenkins, Nexus, Portainer)
       * Monitoring stack (Prometheus, Grafana)
       * Common provisioning (hostname, SSH, users)
    * Optional: Use Terraform to define VM infrastructure
    * Automate full stack deployment for reproducibility and CI/CD workflows
