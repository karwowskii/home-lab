#!/bin/bash

set -e

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
  echo "[INFO] 'jq' not found. Installing..."
  apt update && apt install -y jq
fi

echo "[INFO] Fetching Proxmox configuration..."

# Prompt for VM ID and name
read -rp "Enter a unique VM ID: " VMID
read -rp "Enter a hostname for the VM (e.g., ansible-node): " VM_NAME

# Check if VM ID exists
if qm status "$VMID" &>/dev/null; then
  echo "[ERROR] VM ID $VMID already exists on the node. Please choose a different ID."
  exit 1
fi

# Fetch available nodes
NODES=$(pvesh get /nodes --output-format=json | jq -r '.[].node')
echo "Available Proxmox nodes:"
select NODE in $NODES; do
  [[ -n "$NODE" ]] && break
done

# Fetch available storages
STORAGES=$(pvesh get /nodes/$NODE/storage --output-format=json | jq -r '.[].storage')
echo "Available storage pools:"
select STORAGE in $STORAGES; do
  [[ -n "$STORAGE" ]] && break
done

# Fetch available bridges
BRIDGES=$(pvesh get /nodes/$NODE/network --output-format=json | jq -r '.[] | select(.type == "bridge") | .iface')
echo "Available network bridges:"
select BRIDGE in $BRIDGES; do
  [[ -n "$BRIDGE" ]] && break
done

# Download Ubuntu cloud image
IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_NAME="noble-server-cloudimg-amd64.img"
IMG_PATH="/var/lib/vz/template/$IMG_NAME"

echo "[INFO] Downloading Ubuntu cloud image..."
wget -O "$IMG_PATH" "$IMG_URL"

# Create the VM
echo "[INFO] Creating VM $VMID ($VM_NAME)..."
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE \
  --serial0 socket \
  --boot order=scsi0 \
  --ide2 "$STORAGE":cloudinit \
  --scsihw virtio-scsi-pci

# Import the disk
echo "[INFO] Importing disk to $STORAGE..."
qm importdisk "$VMID" "$IMG_PATH" "$STORAGE"

# Determine the actual disk name
VOLUME_NAME=$(pvesm list "$STORAGE" | awk -v vmid="$VMID" '$0 ~ vmid && $0 ~ "raw" {print $1}' | head -n1 | cut -d ':' -f2)


# Handle SSH key input
read -rp "Enter the path to your SSH public key (leave empty to paste manually): " SSH_KEY_PATH

if [[ -n "$SSH_KEY_PATH" && -f "$SSH_KEY_PATH" ]]; then
  PUBKEY=$(cat "$SSH_KEY_PATH")
else
  echo "Paste your public SSH key"
  read -r PUBKEY
fi

# Configure cloud-init options
qm set "$VMID" \
  --ciuser ubuntu \
  --sshkeys <(echo "$PUBKEY") \
  --ipconfig0 ip=dhcp || { echo "[ERROR] Failed to set cloud-init"; exit 1; }

# Start the VM
echo "[INFO] Starting VM $VMID..."
qm start "$VMID"

echo "[SUCCESS] VM '$VM_NAME' created and started (VMID: $VMID). SSH will be available once DHCP assigns an IP."
