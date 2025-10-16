variable "template_name" {
  description = "Template name for clone"
  type        = string
  default     = "ubuntu-2404-ci"
}

variable "pve_node" {
  description = "Proxmox node name (Example: hos01)"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VMID"
  type        = number
  default     = 200
}

variable "vm_name" {
  description = "VM Name"
  type        = string
  default     = "ubuntu-terraform"
}