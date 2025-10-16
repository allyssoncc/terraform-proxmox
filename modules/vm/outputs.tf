output "vm_ip" {
  description = "IP address of provisioned VM"
  value       = proxmox_vm_qemu.ubuntu_vm.default_ipv4_address
}

output "vm_name" {
  description = "Name of the provisioned VM"
  value       = proxmox_vm_qemu.ubuntu_vm.name
}
