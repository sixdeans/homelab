terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
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
  hostname    = var.container_name
  target_node = var.proxmox_node
  vmid        = var.container_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  
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
    gw      = var.container_gateway
    firewall = false
  }
  
  # Container Features
  # features {
  #   nesting=true
  #   keyctl=true
  #   fuse=true
  # } 
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  start    = true
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
}

# Setup SSH in Caddy container
resource "null_resource" "setup_ssh_caddy" {
  depends_on = [proxmox_lxc.caddy_proxy]
  
  triggers = {
    container_id = proxmox_lxc.caddy_proxy.vmid
  }
  
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${var.proxmox_host} 'echo Waiting for container network... && sleep 10 && for i in 1 2 3 4 5; do pct exec ${var.container_id} -- ping -c 1 1.1.1.1 >/dev/null 2>&1 && break || sleep 3; done && echo Network ready && pct exec ${var.container_id} -- useradd -m -s /bin/bash debian 2>/dev/null || true && pct exec ${var.container_id} -- bash -c \"apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server sudo locales\" && pct exec ${var.container_id} -- bash -c \"echo en_US.UTF-8 UTF-8 > /etc/locale.gen && locale-gen\" && pct exec ${var.container_id} -- systemctl enable ssh && pct exec ${var.container_id} -- systemctl start ssh && pct exec ${var.container_id} -- usermod -aG sudo debian && pct exec ${var.container_id} -- bash -c \"echo debian ALL=\\(ALL\\) NOPASSWD:ALL > /etc/sudoers.d/debian\" && pct exec ${var.container_id} -- chmod 440 /etc/sudoers.d/debian && pct exec ${var.container_id} -- mkdir -p /home/debian/.ssh && pct exec ${var.container_id} -- chmod 700 /home/debian/.ssh && pct exec ${var.container_id} -- bash -c \"echo ${var.ssh_public_key} > /home/debian/.ssh/authorized_keys\" && pct exec ${var.container_id} -- chmod 600 /home/debian/.ssh/authorized_keys && pct exec ${var.container_id} -- chown -R debian:debian /home/debian/.ssh && echo Container ${var.container_id} setup complete'"
    interpreter = ["bash", "-c"]
  }
}

# Create the Technitium DNS LXC container
resource "proxmox_lxc" "technitium_dns" {
  hostname       = var.technitium_name
  target_node = var.proxmox_node
  vmid        = var.technitium_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  
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
    gw      = var.container_gateway
    firewall = false
  }
  
  # Container Features
  # features {
  #   nesting=true
  #   keyctl=true
  #   fuse=true
  # } 
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  start    = true
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
}

# Setup SSH in Technitium container
resource "null_resource" "setup_ssh_technitium" {
  depends_on = [proxmox_lxc.technitium_dns]
  
  triggers = {
    container_id = proxmox_lxc.technitium_dns.vmid
  }
  
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${var.proxmox_host} 'echo Waiting for container network... && sleep 10 && for i in 1 2 3 4 5; do pct exec ${var.technitium_id} -- ping -c 1 1.1.1.1 >/dev/null 2>&1 && break || sleep 3; done && echo Network ready && pct exec ${var.technitium_id} -- useradd -m -s /bin/bash debian 2>/dev/null || true && pct exec ${var.technitium_id} -- bash -c \"apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server sudo locales\" && pct exec ${var.technitium_id} -- bash -c \"echo en_US.UTF-8 UTF-8 > /etc/locale.gen && locale-gen\" && pct exec ${var.technitium_id} -- systemctl enable ssh && pct exec ${var.technitium_id} -- systemctl start ssh && pct exec ${var.technitium_id} -- usermod -aG sudo debian && pct exec ${var.technitium_id} -- bash -c \"echo debian ALL=\\(ALL\\) NOPASSWD:ALL > /etc/sudoers.d/debian\" && pct exec ${var.technitium_id} -- chmod 440 /etc/sudoers.d/debian && pct exec ${var.technitium_id} -- mkdir -p /home/debian/.ssh && pct exec ${var.technitium_id} -- chmod 700 /home/debian/.ssh && pct exec ${var.technitium_id} -- bash -c \"echo ${var.ssh_public_key} > /home/debian/.ssh/authorized_keys\" && pct exec ${var.technitium_id} -- chmod 600 /home/debian/.ssh/authorized_keys && pct exec ${var.technitium_id} -- chown -R debian:debian /home/debian/.ssh && echo Container ${var.technitium_id} setup complete'"
    interpreter = ["bash", "-c"]
  }
}

# Create the TinyAuth LXC container
resource "proxmox_lxc" "tinyauth" {
  hostname       = var.tinyauth_name
  target_node = var.proxmox_node
  vmid        = var.tinyauth_id
  ostemplate  = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  
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
    gw      = var.container_gateway
    firewall = false
  }
  
  # Container Features
  # features {
  #   nesting=true
  #   keyctl=true
  #   fuse=true
  # } 
  
  # DNS Configuration
  nameserver = var.container_dns_servers
  searchdomain = "local"
  
  # SSH Configuration
  ssh_public_keys = var.ssh_public_key
  
  # Container Options
  onboot   = true
  start    = true
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
}

# Setup SSH in TinyAuth container
resource "null_resource" "setup_ssh_tinyauth" {
  depends_on = [proxmox_lxc.tinyauth]
  
  triggers = {
    container_id = proxmox_lxc.tinyauth.vmid
  }
  
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no root@${var.proxmox_host} 'echo Waiting for container network... && sleep 10 && for i in 1 2 3 4 5; do pct exec ${var.tinyauth_id} -- ping -c 1 1.1.1.1 >/dev/null 2>&1 && break || sleep 3; done && echo Network ready && pct exec ${var.tinyauth_id} -- useradd -m -s /bin/bash debian 2>/dev/null || true && pct exec ${var.tinyauth_id} -- bash -c \"apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server sudo locales\" && pct exec ${var.tinyauth_id} -- bash -c \"echo en_US.UTF-8 UTF-8 > /etc/locale.gen && locale-gen\" && pct exec ${var.tinyauth_id} -- systemctl enable ssh && pct exec ${var.tinyauth_id} -- systemctl start ssh && pct exec ${var.tinyauth_id} -- usermod -aG sudo debian && pct exec ${var.tinyauth_id} -- bash -c \"echo debian ALL=\\(ALL\\) NOPASSWD:ALL > /etc/sudoers.d/debian\" && pct exec ${var.tinyauth_id} -- chmod 440 /etc/sudoers.d/debian && pct exec ${var.tinyauth_id} -- mkdir -p /home/debian/.ssh && pct exec ${var.tinyauth_id} -- chmod 700 /home/debian/.ssh && pct exec ${var.tinyauth_id} -- bash -c \"echo ${var.ssh_public_key} > /home/debian/.ssh/authorized_keys\" && pct exec ${var.tinyauth_id} -- chmod 600 /home/debian/.ssh/authorized_keys && pct exec ${var.tinyauth_id} -- chown -R debian:debian /home/debian/.ssh && echo Container ${var.tinyauth_id} setup complete'"
    interpreter = ["bash", "-c"]
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
  value       = proxmox_lxc.caddy_proxy.hostname
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
  value       = proxmox_lxc.technitium_dns.hostname
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
  value       = proxmox_lxc.tinyauth.hostname
}

output "tinyauth_ssh_connection" {
  description = "SSH connection command for TinyAuth"
  value       = "ssh ${var.container_user}@${split("/", var.tinyauth_ip_address)[0]}"
}
