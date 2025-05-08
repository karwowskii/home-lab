# Home Lab Infrastructure

This repository contains the infrastructure and applications used in my home lab/sandbox for DevOps, although this is all still being elaborated upon on the daily.

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

## 🚀 Getting Started

### 1. Prerequisites

- Ubuntu 24.04+ VMs
- SSH access to Ansible host

### 2. Install Docker & Compose

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install_docker.yml
