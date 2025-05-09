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

echo "[INFO] Running provisioning playbooks on Ansible node at $ANSIBLE_NODE_IP..."

REMOTE_COMMANDS=$(cat <<'EOF'
cd ~/home-lab/ansible

echo "[INFO] Running bootstrap-common.yml..."
ansible-playbook -i inventory.ini playbooks/bootstrap-common.yml || { echo "[ERROR] Failed: bootstrap-common.yml"; exit 1; }

echo "[INFO] Running provision-docker.yml..."
ansible-playbook -i inventory.ini playbooks/provision-docker.yml || { echo "[ERROR] Failed: provision-docker.yml"; exit 1; }

echo "[INFO] Running provision-monitoring.yml..."
ansible-playbook -i inventory.ini playbooks/provision-monitoring.yml || { echo "[ERROR] Failed: provision-monitoring.yml"; exit 1; }

echo "[INFO] All playbooks completed successfully."
EOF
)

ssh -o StrictHostKeyChecking=no "${ANSIBLE_NODE_USER}@${ANSIBLE_NODE_IP}" "$REMOTE_COMMANDS"

