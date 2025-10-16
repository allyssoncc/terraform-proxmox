#!/bin/bash

# Configuration variables
VMID=900
VM_NAME="ubuntu-2404-ci" 
STORAGE_DISK="local-lvm"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_FILE=$(basename "$IMAGE_URL")
DOWNLOAD_DIR="/tmp"
CI_USER="allysson"
CI_PASS="Escolha1SenhaForte!"

die() {
    echo "ERRO: $1" >&2
    exit 1
}

# 0. Prerequisite check and installation (libguestfs-tools)
if ! command -v virt-customize &> /dev/null; then
    echo "Installing libguestfs-tools (required for virt-customize)..."
    apt update
    apt install libguestfs-tools -y || die "Failed to install libguestfs-tools."
else
    echo "virt-customize tool already installed. Skipping..."
fi

echo "Starting the creation of the cloud-init template: $VM_NAME (VMID $VMID)"
cd "$DOWNLOAD_DIR" || die "Could not change to directory $DOWNLOAD_DIR"
echo "--------------------------------------------------------"

# 1. Image download
if [ ! -f "$IMAGE_FILE" ]; then
    echo "1a. Downloading the cloud-init image..."
    wget -q "$IMAGE_URL" || die "Failed to download image."
else
    echo "1a. Image $IMAGE_FILE already exists. Skipping..."
fi


# 2. Customization: Install QEMU Guest Agent
echo "2. Customizing the image: Installing QEMU Guest Agent..."
virt-customize --add "$IMAGE_FILE" \
    --install qemu-guest-agent || die "Failed to customize image with virt-customize."
echo "QEMU Guest Agent installed successfully!"


# 3. Create the VM and import the disk
echo "3. Creating the VM and importing the disk..."
qm create $VMID --memory 2048 --core 2 --name "$VM_NAME" \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26 \
  --cores 2 \
  --memory 2048 || die "Failed to create VM."

qm importdisk $VMID "$IMAGE_FILE" "$STORAGE_DISK" || die "Failed to import disk."

# 4. Attach, configure hardware and boot
echo "4. Attaching disk and configuring hardware..."
qm set $VMID --scsihw virtio-scsi-pci --scsi0 "$STORAGE_DISK":vm-$VMID-disk-0
qm set $VMID --ide2 "$STORAGE_DISK":cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga virtio

# 5. Configure QEMU Guest Agent and cloud-init (User and DHCP via Proxmox)
echo "5. Configuring QEMU Guest Agent and cloud-init with user $CI_USER, password and DHCP..."
qm set $VMID --agent enabled=1
qm set $VMID --ciuser "$CI_USER"
qm set $VMID --cipassword "$CI_PASS"
qm set $VMID --ipconfig0 ip=dhcp
# The SSH key must be injected by Terraform when cloning this template.

# 6. Convert VM to template
echo "6. Converting the VM to a Template..."
qm template $VMID || die "Failed to convert to template."

# 7. Cleanup and Completion
echo "7. Cleaning up temporary files..."
rm -f "$IMAGE_FILE"
echo "--------------------------------------------------------"
echo "Template cloud-init '$VM_NAME' (VMID $VMID) created successfully!"