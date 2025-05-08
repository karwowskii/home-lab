#!/bin/bash
set -e

echo "[INFO] Starting Home Lab setup on clean Proxmox host..."

REQUIRED_PKGS=("wget" "curl" "jq" "cloud-image-utils" "qemu-utils")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[INFO] Installing missing package: $pkg"
        apt update && apt install -y "$pkg"
    fi
done

echo "[INFO] Downloading create-ansible-node.sh..."
wget -O create-ansible-node.sh https://raw.githubusercontent.com/karwowskii/home-lab/main/01-scripts/create-ansible-node.sh
chmod +x create-ansible-node.sh

echo "[INFO] Running create-ansible-node.sh to initialize orchestration VM..."
./create-ansible-node.sh

echo "[INFO] Control node creation complete. You may now SSH into the VM and continue setup."
