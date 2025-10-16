# Configure the required provider and version
terraform {
  required_version = ">=1.6.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

# Proxmox Provider Configuration
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_tls_insecure     = true
  pm_api_token_id     = var.proxmox_user
  pm_api_token_secret = var.proxmox_token_secret 
}