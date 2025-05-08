#!/bin/bash

# === CONFIG ===
VMID=9000
VM_NAME="ansible-node"
ISO_NAME="ubuntu-24.04-live-server-amd64.iso"
ISO_PATH="/var/lib/vz/template/iso/$ISO_NAME"
STORAGE="local"           # or local-lvm if you want thin provisioning
BRIDGE="vmbr0"
RAM=2048
DISK_SIZE=20G
CORES=2

# === STEP 1: Check or download ISO ===
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Ubuntu 24.04 ISO..."
    wget -O "$ISO_PATH" https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
else
    echo "ISO already present."
fi

# === STEP 2: Create VM ===
echo "Creating VM $VMID ($VM_NAME)..."
qm create $VMID \
    --name $VM_NAME \
    --memory $RAM \
    --cores $CORES \
    --net0 virtio,bridge=$BRIDGE \
    --cdrom $STORAGE:iso/$ISO_NAME \
    --boot order=cdrom \
    --ostype l26 \
    --scsihw virtio-scsi-pci

# === STEP 3: Add disk ===
echo "Adding disk..."
qm set $VMID --scsi0 $STORAGE:{$DISK_SIZE}

# === STEP 4: Attach CloudInit drive (if you want) ===
qm set $VMID --ide2 $STORAGE:cloudinit

# === STEP 5: Enable serial console ===
qm set $VMID --serial0 socket --vga serial0

# === STEP 6: Start the VM ===
echo "Starting VM $VMID..."
qm start $VMID

echo "VM $VM_NAME created and started. Connect via Proxmox GUI or console to complete OS installation."
