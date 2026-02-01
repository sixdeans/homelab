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

# Create the Caddy reverse proxy LXC container
resource "proxmox_lxc" "caddy_proxy" {
  name        = var.container_name
  target_node = var.proxmox_node
  vmid        = var.container_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.5-1_amd64.tar.zst"
  
  # Container Hardware Configuration
  cores   = var.container_cores
  memory  = var.container_memory
  swap    = 512
  
  # Disk Configuration
  rootfs {
    storage = var.container_storage
    size    = var.container_disk_size
  }
  
  # Network Configuration
  network {
    name    = "eth0"
    bridge  = var.container_bridge
    ip      = var.container_ip_address
    gateway = var.container_gateway
    firewall = false
  }
  
  # Container Features
  features = var.container_features
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  startup  = "order=1"
  tags     = var.container_tags
  
  # Unprivileged container settings
  unprivileged = true
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      rootfs,
    ]
  }
  
  # Wait for container to be ready
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip",
    ]
    
    connection {
      type        = "ssh"
      user        = var.container_user
      private_key = file("~/.ssh/id_rsa")
      host        = split("/", var.container_ip_address)[0]
      timeout     = "5m"
    }
  }
}

# Create the Technitium DNS LXC container
resource "proxmox_lxc" "technitium_dns" {
  name        = var.technitium_name
  target_node = var.proxmox_node
  vmid        = var.technitium_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.5-1_amd64.tar.zst"
  
  # Container Hardware Configuration
  cores   = var.technitium_cores
  memory  = var.technitium_memory
  swap    = 512
  
  # Disk Configuration
  rootfs {
    storage = var.container_storage
    size    = var.technitium_disk_size
  }
  
  # Network Configuration
  network {
    name    = "eth0"
    bridge  = var.container_bridge
    ip      = var.technitium_ip_address
    gateway = var.container_gateway
    firewall = false
  }
  
  # Container Features
  features = var.container_features
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  startup  = "order=2"
  tags     = var.technitium_tags
  
  # Unprivileged container settings
  unprivileged = true
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      rootfs,
    ]
  }
  
  # Wait for container to be ready
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip",
    ]
    
    connection {
      type        = "ssh"
      user        = var.container_user
      private_key = file("~/.ssh/id_rsa")
      host        = split("/", var.technitium_ip_address)[0]
      timeout     = "5m"
    }
  }
}

# Create the TinyAuth LXC container
resource "proxmox_lxc" "tinyauth" {
  name        = var.tinyauth_name
  target_node = var.proxmox_node
  vmid        = var.tinyauth_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.5-1_amd64.tar.zst"
  
  # Container Hardware Configuration
  cores   = var.tinyauth_cores
  memory  = var.tinyauth_memory
  swap    = 512
  
  # Disk Configuration
  rootfs {
    storage = var.container_storage
    size    = var.tinyauth_disk_size
  }
  
  # Network Configuration
  network {
    name    = "eth0"
    bridge  = var.container_bridge
    ip      = var.tinyauth_ip_address
    gateway = var.container_gateway
    firewall = false
  }
  
  # Container Features
  features = var.container_features
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  startup  = "order=3"
  tags     = var.tinyauth_tags
  
  # Unprivileged container settings
  unprivileged = true
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      rootfs,
    ]
  }
  
  # Wait for container to be ready
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip",
    ]
    
    connection {
      type        = "ssh"
      user        = var.container_user
      private_key = file("~/.ssh/id_rsa")
      host        = split("/", var.tinyauth_ip_address)[0]
      timeout     = "5m"
    }
  }
}

# Output the container information
output "container_ip_address" {
  description = "IP address of the Caddy proxy container"
  value       = split("/", var.container_ip_address)[0]
}

output "container_id" {
  description = "Container ID"
  value       = proxmox_lxc.caddy_proxy.vmid
}

output "container_name" {
  description = "Container name"
  value       = proxmox_lxc.caddy_proxy.name
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh ${var.container_user}@${split("/", var.container_ip_address)[0]}"
}

# Output Technitium DNS container information
output "technitium_ip_address" {
  description = "IP address of the Technitium DNS container"
  value       = split("/", var.technitium_ip_address)[0]
}

output "technitium_id" {
  description = "Technitium DNS container ID"
  value       = proxmox_lxc.technitium_dns.vmid
}

output "technitium_name" {
  description = "Technitium DNS container name"
  value       = proxmox_lxc.technitium_dns.name
}

output "technitium_ssh_connection" {
  description = "SSH connection command for Technitium DNS"
  value       = "ssh ${var.container_user}@${split("/", var.technitium_ip_address)[0]}"
}

# Output TinyAuth container information
output "tinyauth_ip_address" {
  description = "IP address of the TinyAuth container"
  value       = split("/", var.tinyauth_ip_address)[0]
}

output "tinyauth_id" {
  description = "TinyAuth container ID"
  value       = proxmox_lxc.tinyauth.vmid
}

output "tinyauth_name" {
  description = "TinyAuth container name"
  value       = proxmox_lxc.tinyauth.name
}

output "tinyauth_ssh_connection" {
  description = "SSH connection command for TinyAuth"
  value       = "ssh ${var.container_user}@${split("/", var.tinyauth_ip_address)[0]}"
}
