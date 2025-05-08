#!/bin/bash
set -e

echo "[*] Updating system and installing packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y cloud-init net-tools curl sudo openssh-server qemu-guest-agent

echo "[*] Enabling cloud-init for DHCP..."
sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: true
EOF

sudo netplan apply

echo "[*] Cleaning up and preparing for template..."
sudo cloud-init clean
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "[*] Enabling services..."
sudo systemctl enable qemu-guest-agent
sudo systemctl enable cloud-init

echo "[*] Done. Shutting down..."
sudo poweroff
