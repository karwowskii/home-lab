#!/bin/bash
set -e

# Ensure required dependencies are installed
for pkg in jq cloud-image-utils qemu-utils; do
  if ! command -v "${pkg/cloud-image-utils/cloud-localds}" &>/dev/null && ! command -v "${pkg/qemu-utils/qemu-img}" &>/dev/null; then
    echo "[INFO] '$pkg' not found. Installing..."
    apt update && apt install -y "$pkg"
  fi
done

echo "[INFO] Gathering Proxmox configuration..."

# Prompt for input
read -rp "Enter a unique VM ID: " VMID
read -rp "Enter a hostname for the VM (e.g., ansible-node): " VM_NAME

if qm status "$VMID" &>/dev/null; then
  echo "[ERROR] VM ID $VMID already exists. Choose another."
  exit 1
fi

NODES=$(pvesh get /nodes --output-format=json | jq -r '.[].node')
echo "Available nodes:"
select NODE in $NODES; do [[ -n "$NODE" ]] && break; done

STORAGES=$(pvesh get /nodes/$NODE/storage --output-format=json | jq -r '.[].storage')
echo "Available storages:"
select STORAGE in $STORAGES; do [[ -n "$STORAGE" ]] && break; done

BRIDGES=$(pvesh get /nodes/$NODE/network --output-format=json | jq -r '.[] | select(.type == "bridge") | .iface')
echo "Available network bridges:"
select BRIDGE in $BRIDGES; do [[ -n "$BRIDGE" ]] && break; done

# Download Ubuntu cloud image
IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_NAME="noble-server-cloudimg-amd64.img"
IMG_PATH="/var/lib/vz/template/${IMG_NAME}"
echo "[INFO] Downloading Ubuntu cloud image..."
wget -O "$IMG_PATH" "$IMG_URL"

# Ask for target disk size
read -rp "Enter desired disk size (e.g., 20G): " DISK_SIZE
echo "[INFO] Resizing image to $DISK_SIZE..."
qemu-img resize "$IMG_PATH" "$DISK_SIZE"

# Create VM
echo "[INFO] Creating VM $VMID ($VM_NAME)..."
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge="$BRIDGE" \
  --serial0 socket \
  --scsihw virtio-scsi-pci \
  --boot order=scsi0 \
  --agent enabled=1

# Import disk
echo "[INFO] Importing OS disk..."
qm importdisk "$VMID" "$IMG_PATH" "$STORAGE"
DISK_ID=$(pvesm list "$STORAGE" | awk -v vmid="$VMID" '$1 ~ vmid && /disk-0/ {print $1}')

# Attach disk
qm set "$VMID" --scsi0 "$DISK_ID"

# SSH key input
read -rp "Enter path to SSH public key (or press enter to paste manually): " SSH_KEY_PATH
if [[ -n "$SSH_KEY_PATH" && -f "$SSH_KEY_PATH" ]]; then
  PUBKEY=$(cat "$SSH_KEY_PATH")
else
  echo "Paste your public SSH key (one line):"
  read -r PUBKEY
fi

# Generate cloud-init ISO with user-data and meta-data
CLOUDINIT_DIR="/tmp/cloudinit-${VMID}"
mkdir -p "$CLOUDINIT_DIR"

cat > "${CLOUDINIT_DIR}/user-data" <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - ${PUBKEY}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable --now qemu-guest-agent
EOF

cat > "${CLOUDINIT_DIR}/meta-data" <<EOF
instance-id: iid-${VMID}
local-hostname: ${VM_NAME}
EOF

ISO_PATH="${CLOUDINIT_DIR}/cloudinit-${VMID}.iso"
cloud-localds "$ISO_PATH" "${CLOUDINIT_DIR}/user-data" "${CLOUDINIT_DIR}/meta-data"

# Import ISO as disk
echo "[INFO] Importing cloud-init ISO..."
qm importdisk "$VMID" "$ISO_PATH" "$STORAGE" --format raw
CLOUDINIT_DISK=$(qm config "$VMID" | awk -F ': ' '/^unused[0-9]+:/ {print $2}' | grep '\.raw')

# Attach ISO to VM as CD-ROM
qm set "$VMID" --ide3 "$CLOUDINIT_DISK",media=cdrom

# Cloud-init config
qm set "$VMID" \
  --ciuser ubuntu \
  --sshkeys <(echo "$PUBKEY") \
  --ipconfig0 ip=dhcp

# Start VM
echo "[INFO] Starting VM $VMID..."
qm start "$VMID"

echo "[SUCCESS] VM '$VM_NAME' created and started (VMID: $VMID)"
#echo "\n*********NOTE: PLEASE WAIT FOR AROUND 1 MINUTE BEFORE ATTEMPTING THE FOLLOWING*********zn"
#echo "Fetch IP when ready with:"
#echo "    qm guest cmd $VMID network-get-interfaces"



echo "[INFO] Waiting for the VM to initialise..."

while true; do
  IP=$(qm guest cmd "$VMID" network-get-interfaces 2>/dev/null | \
    jq -r '.[] | select(.name != "lo") | .["ip-addresses"][] | select(."ip-address-type" == "ipv4") | ."ip-address"' | head -n1)

  if [[ -n "$IP" ]]; then
    echo "[SUCCESS] VM '$VM_NAME' is now online with IP: $IP"
    break
  else
    sleep 15
  fi
done

# Define where inventory.ini should be created/updated
INVENTORY_PATH="../02-ansible/inventory.ini"

# Ensure the Ansible directory exists
mkdir -p "$(dirname "$INVENTORY_PATH")"

GROUP_NAME=$(echo "$VM_NAME" | cut -d'-' -f1)  # e.g., 'ansible', 'docker', 'monitoring'

# Add group header if not already present
if ! grep -q "^\[$GROUP_NAME\]$" "$INVENTORY_PATH" 2>/dev/null; then
  echo -e "\n[$GROUP_NAME]" >> "$INVENTORY_PATH"
fi

# Append host entry
echo "$IP ansible_user=ubuntu" >> "$INVENTORY_PATH"

# Add common vars section if not present
if ! grep -q "^\[all:vars\]$" "$INVENTORY_PATH" 2>/dev/null; then
  cat >> "$INVENTORY_PATH" <<EOF

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
fi

echo "[INFO] $INVENTORY_PATH updated with $VM_NAME ($IP)"

# Save connection info for downstream script
cat <<EOF > /tmp/ansible-node-info
ANSIBLE_NODE_IP=$IP
ANSIBLE_NODE_USER=ubuntu
EOF