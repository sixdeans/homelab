terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Configure the Proxmox Provider
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# Create the Caddy reverse proxy VM
resource "proxmox_vm_qemu" "caddy_proxy" {
  name        = var.vm_name
  target_node = var.proxmox_node
  vmid        = var.vm_id
  clone       = var.cloud_init_template
  full_clone  = true
  
  # VM Hardware Configuration
  cores   = var.vm_cores
  sockets = 1
  memory  = var.vm_memory
  
  # Boot Configuration
  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-pci"
  
  # Disk Configuration
  disk {
    slot     = 0
    type     = "scsi"
    storage  = var.vm_storage
    size     = var.vm_disk_size
    format   = "raw"
    cache    = "writeback"
    backup   = true
    replicate = false
  }
  
  # Network Configuration
  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }
  
  # Cloud-init Configuration
  os_type = "cloud-init"
  
  # Cloud-init settings
  ciuser     = var.vm_user
  cipassword = "changeme123!"  # This will be disabled after SSH key setup
  sshkeys    = var.ssh_public_key
  
  # Network configuration via cloud-init
  ipconfig0 = "ip=${var.vm_ip_address},gw=${var.vm_gateway}"
  
  # DNS configuration
  nameserver = var.vm_dns_servers
  
  # VM Options
  agent    = 1
  onboot   = true
  startup  = "order=1"
  tags     = var.vm_tags
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
  
  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip",
    ]
    
    connection {
      type        = "ssh"
      user        = var.vm_user
      private_key = file("~/.ssh/id_rsa")
      host        = split("/", var.vm_ip_address)[0]
      timeout     = "5m"
    }
  }
}

# Output the VM information
output "vm_ip_address" {
  description = "IP address of the Caddy proxy VM"
  value       = split("/", var.vm_ip_address)[0]
}

output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.caddy_proxy.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.caddy_proxy.name
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh ${var.vm_user}@${split("/", var.vm_ip_address)[0]}"
}
