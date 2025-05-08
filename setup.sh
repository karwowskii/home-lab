#!/bin/bash

echo "Enter the full path to your public SSH key (e.g., ~/.ssh/id_rsa.pub):"
read -r ssh_key_path

if [[ ! -f $ssh_key_path ]]; then
  echo "❌ Error: File not found at $ssh_key_path"
  exit 1
fi

ssh_key_contents=$(cat "$ssh_key_path")

# Create or update Ansible var file
cat > ansible/group_vars/all.yml <<EOF
---
ansible_ssh_public_key: "${ssh_key_contents}"
EOF

echo "SSH key saved to ansible/group_vars/all.yml"
