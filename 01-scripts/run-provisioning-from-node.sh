#!/bin/bash
set -e

ANSIBLE_INFO_FILE="/tmp/ansible-node-info"

if [[ ! -f "$ANSIBLE_INFO_FILE" ]]; then
  echo "[ERROR] $ANSIBLE_INFO_FILE not found. Did you run create-ansible-node.sh?"
  exit 1
fi

source "$ANSIBLE_INFO_FILE"

if [[ -z "$ANSIBLE_NODE_IP" ]]; then
  echo "[ERROR] Missing IP in $ANSIBLE_INFO_FILE"
  exit 1
fi

echo "[INFO] Running provisioning playbooks on Ansible node at $ANSIBLE_NODE_IP..."

REMOTE_COMMANDS=$(cat <<'EOF'
cd /home/ubuntu/home-lab/02-ansible || { echo "[ERROR] home-lab repo not found"; exit 1; }

echo "[INFO] Running bootstrap-common.yml..."
source /home/ubuntu/ansible-venv/bin/activate
ansible-playbook -i inventory.ini playbooks/bootstrap-common.yml || { echo "[ERROR] Failed: bootstrap-common.yml"; exit 1; }

echo "[INFO] Running provision-docker.yml..."
ansible-playbook -i inventory.ini playbooks/provision-docker.yml || { echo "[ERROR] Failed: provision-docker.yml"; exit 1; }

echo "[INFO] Running provision-monitoring.yml..."
ansible-playbook -i inventory.ini playbooks/provision-monitoring.yml || { echo "[ERROR] Failed: provision-monitoring.yml"; exit 1; }

echo "[INFO] All playbooks completed successfully."
EOF
)

ssh -o StrictHostKeyChecking=no "ubuntu@${ANSIBLE_NODE_IP}" "$REMOTE_COMMANDS"
