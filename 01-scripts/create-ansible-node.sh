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

# Fetch available nodes
NODES=$(pvesh get /nodes | jq -r '.[].node')
echo "Available Proxmox nodes:"
select NODE in $NODES; do
  [[ -n "$NODE" ]] && break
done

# Fetch available storages
STORAGES=$(pvesh get /nodes/$NODE/storage | jq -r '.[].storage')
echo "Available storage pools:"
select STORAGE in $STORAGES; do
  [[ -n "$STORAGE" ]] && break
done

# Fetch available bridges
BRIDGES=$(pvesh get /nodes/$NODE/network | jq -r '.[] | select(.type == "bridge") | .iface')
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

# Attach imported disk to VM
qm set "$VMID" --scsi0 "$STORAGE":vm-"$VMID"-disk-0

# Add SSH key
read -rp "Enter the path to your SSH public key (e.g., ~/.ssh/id_rsa.pub): " SSH_KEY_PATH
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "SSH key not found at $SSH_KEY_PATH"
  exit 1
fi
PUBKEY=$(cat "$SSH_KEY_PATH")

# Configure cloud-init options
qm set "$VMID" \
  --ciuser ubuntu \
  --sshkeys "$PUBKEY" \
  --ipconfig0 ip=dhcp

# Resize disk (optional, uncomment if needed)
# qm resize "$VMID" scsi0 +20G

# Start the VM
echo "[INFO] Starting VM $VMID..."
qm start "$VMID"

echo "VM '$VM_NAME' created and started (VMID: $VMID). SSH will be available once DHCP assigns an IP."
