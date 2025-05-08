output "ubuntu_docker_name" {
  value = proxmox_vm_qemu.ubuntu_docker.name
}

output "ubuntu_docker_id" {
  value = proxmox_vm_qemu.ubuntu_docker.vmid
}
