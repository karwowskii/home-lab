variable "pm_api_url" {
  type        = string
  description = "Proxmox API URL"
}

variable "pm_user" {
  type        = string
  description = "Proxmox API user"
}

variable "pm_password" {
  type        = string
  description = "Proxmox API password or token secret"
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH key to inject into cloud-init"
}

