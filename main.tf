module "vm_ubuntu" {
  source = "./modules/vm"

  pve_node              = var.pve_node
  template_name         = "ubuntu-2404-ci"

  providers = {
    proxmox = proxmox
  }
}
