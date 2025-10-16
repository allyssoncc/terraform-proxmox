variable "proxmox_api_url" {
  description = "Proxmox API URL (Example: https://192.168.30.200:8006/api2/json)"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox API User (Example: ansible@pam)"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "pve_node" {
  description = "Proxmox node name (Example: hos01)"
  type        = string
}