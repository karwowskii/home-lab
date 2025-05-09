#!/bin/bash

SECRETS_FILE="../02-ansible/vars/proxmox_secrets.yml"

echo "[INFO] Creating Ansible Proxmox secrets file..."

read -p "Proxmox Host (e.g., 192.168.0.10): " host
read -p "Proxmox API User (e.g., root@pam): " user
read -p "API Token ID (e.g., ansible): " token_id
read -s -p "API Token Secret: " token_secret
echo

mkdir -p "$(dirname "$SECRETS_FILE")"

cat > "$SECRETS_FILE" <<EOF
proxmox_host: $host
api_user: $user
api_token_id: $token_id
api_token_secret: $token_secret
EOF

echo "[SUCCESS] Proxmox secrets file created at $SECRETS_FILE"
