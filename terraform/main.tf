terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.11" # or latest from GitHub
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_api_token_id         = var.pm_api_token_id
  pm_api_token_secret     = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ubuntu_docker" {
  name        = "ubuntu-docker"
  target_node = "host"
  clone       = "ubuntu-template"

  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    size     = "40G"
    type     = "scsi"
    storage  = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp"

  sshkeys = file("~/.ssh/id_rsa.pub")
  ciuser = "ubuntu"
}

