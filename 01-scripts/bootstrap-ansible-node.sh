#!/bin/bash
set -e

ANSIBLE_INFO_FILE="/tmp/ansible-node-info"

if [[ ! -f "$ANSIBLE_INFO_FILE" ]]; then
  echo "[ERROR] $ANSIBLE_INFO_FILE not found. Did you run create-ansible-node.sh?"
  exit 1
fi

source "$ANSIBLE_INFO_FILE"

if [[ -z "$ANSIBLE_NODE_IP" || -z "$ANSIBLE_NODE_USER" ]]; then
  echo "[ERROR] Missing IP or user info in $ANSIBLE_INFO_FILE"
  exit 1
fi

echo "[INFO] Bootstrapping Ansible node at $ANSIBLE_NODE_IP..."

REMOTE_COMMANDS=$(cat <<'EOF'
set -e

echo "[INFO] Updating and installing required packages..."
sudo apt update
sudo apt install -y ansible git python3-pip python3-venv unzip wget || { echo "[ERROR] Package installation failed."; exit 1; }

echo "[INFO] Installing Terraform manually..."
TERRAFORM_VERSION="1.8.1"
cd /tmp
wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip || { echo "[ERROR] Failed to download Terraform."; exit 1; }
un
