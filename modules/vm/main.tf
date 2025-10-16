# Creating and configuring the VM
resource "proxmox_vm_qemu" "ubuntu_vm" {
  # Basic settings
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.pve_node

  # Template
  clone      = var.template_name
  full_clone = true

  # Hardware
  memory  = 2048
  agent   = 1
  scsihw  = "virtio-scsi-pci"

  cpu {
    cores = 2
  }

  disk {
    slot    = "scsi0"
    size    = "32G"
    storage = "local-lvm"
    type    = "disk"
  }

  disk {
    format  = "raw"
    type    = "cloudinit"
    storage = "local-lvm"
    slot    = "ide2"
  }

  vga {
    type = "virtio"
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init ---
  ipconfig0 = "ip=dhcp"
  sshkeys   = file("~/.ssh/id_rsa_ansible.pub")
  ciuser    = "allysson"

  # Wait time for Cloud-init to complete
  # Terraform waits for the VM to be ready for the SSH connection.
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# null_resource for provisioning (cycle break)
# This resource ensures that the VM is created and the IP resolved before
# attempting the SSH connection and running Ansible.
resource "null_resource" "ansible_provisioning" {
  # EXPLICIT DEPENDENCY: Ensures the VM exists before starting provisioning.
  depends_on = [proxmox_vm_qemu.ubuntu_vm]
  
  # Provisioner: Ansible Execution
  provisioner "local-exec" {
    command = <<EOT
      ip="${proxmox_vm_qemu.ubuntu_vm.default_ipv4_address}"

      echo "Waiting for VM IP..."
      for i in {1..10}; do
        if [ -n "$ip" ]; then
          echo "IP found: $ip"
          break
        else
          echo "No IP, waiting 10s..."
          sleep 10
        fi
      done

      if [ -z "$ip" ]; then
        echo "Error: IP not found after some time."
        exit 1
      fi

      # 1. Create a temporary inventory with dynamic IP
      echo "[new_vm_to_configure]" > ${path.root}/inventory
      echo "$ip ansible_user=allysson" >> ${path.root}/inventory

      # 2. Run playbook
      # ssh-agent is required because the key has a passphrase
      ansible-playbook -i ${path.root}/inventory ${path.root}/ansible/setup_vm.yml \
      --private-key ~/.ssh/id_rsa_ansible \
      -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"

      # 3. Remove temporary inventory
      rm -f ${path.root}/inventory
    EOT
  }
}