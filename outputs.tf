output "vm_ip_address" {
  description = "IP address of provisioned VM"
  value = module.vm_ubuntu.vm_ip
}

output "vm_name" {
  description = "Name of the provisioned VM"
  value = module.vm_ubuntu.vm_name
}