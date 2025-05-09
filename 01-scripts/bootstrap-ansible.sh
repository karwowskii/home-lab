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
sudo apt install -y ansible terraform git python3-pip python3-venv || { echo "[ERROR] Package installation failed."; exit 1; }

echo "[INFO] Verifying Ansible installation..."
if ! command -v ansible >/dev/null; then
  echo "[ERROR] Ansible installation failed."
  exit 1
fi

echo "[INFO] Installing Python packages for Ansible..."
pip3 install --user netaddr jmespath || { echo "[ERROR] Python package installation failed."; exit 1; }

echo "[INFO] Setting up home-lab repository..."
if [ ! -d \"$HOME/home-lab\" ]; then
  git clone https://github.com/karwowskii/home-lab.git || { echo "[ERROR] Git clone failed."; exit 1; }
else
  cd $HOME/home-lab && git pull
fi

echo "[INFO] Bootstrap complete. Ansible node is ready."
EOF
)

ssh -o StrictHostKeyChecking=no "${ANSIBLE_NODE_USER}@${ANSIBLE_NODE_IP}" "$REMOTE_COMMANDS"
