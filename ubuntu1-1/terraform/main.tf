# =============================================================================
# Terraform Configuration for libvirt/KVM
#
# Provisions Ubuntu VMs with cloud-init configuration.
# Works with KVM/QEMU via libvirt.
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Requirements:
#   - libvirt/KVM installed
#   - Terraform libvirt provider
#   - Ubuntu cloud image downloaded
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "libvirt" {
  uri = var.libvirt_uri
}

# =============================================================================
# Base Volume (Ubuntu Cloud Image)
# =============================================================================

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-base.qcow2"
  pool   = var.storage_pool
  source = var.ubuntu_image_path
  format = "qcow2"
}

# =============================================================================
# VM Volume (Cloned from Base)
# =============================================================================

resource "libvirt_volume" "vm_disk" {
  name           = "${var.vm_name}-disk.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = var.disk_size_gb * 1024 * 1024 * 1024
  format         = "qcow2"
}

# =============================================================================
# Cloud-Init Configuration
# =============================================================================

resource "libvirt_cloudinit_disk" "cloud_init" {
  name      = "${var.vm_name}-cloudinit.iso"
  pool      = var.storage_pool
  user_data = file(var.cloud_init_file)

  meta_data = <<-EOF
    instance-id: ${var.vm_name}
    local-hostname: ${var.vm_name}
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      ens3:
        dhcp4: true
  EOF
}

# =============================================================================
# Virtual Machine
# =============================================================================

resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpu_count

  cloudinit = libvirt_cloudinit_disk.cloud_init.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.vm_disk.id
    scsi      = false
  }

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }

  # Ensure VM starts on boot
  autostart = var.autostart
}
