# Proxmox Provider Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "proxmox_host" {
  description = "Proxmox host IP or hostname for SSH access (used by null_resource provisioners)"
  type        = string
}

# LXC Container Configuration Variables
variable "container_name" {
  description = "Name of the LXC container"
  type        = string
  default     = "caddy-proxy"
}

variable "container_id" {
  description = "LXC container ID"
  type        = number
  default     = 100
}

variable "container_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "container_memory" {
  description = "Memory in MB"
  type        = number
  default     = 1024
}

variable "container_disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "10G"
}

variable "container_storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

# Network Configuration
variable "container_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "container_ip_address" {
  description = "Static IP address for the container (CIDR notation)"
  type        = string
  default     = "192.168.1.100/24"
}

variable "container_gateway" {
  description = "Gateway IP address"
  type        = string
  default     = "192.168.1.1"
}

variable "container_dns_servers" {
  description = "DNS servers"
  type        = string
  default     = "1.1.1.1 8.8.8.8"
}

# LXC Template Configuration
variable "lxc_template" {
  description = "LXC template ID (Debian 13)"
  type        = number
  default     = 9000
}

variable "ssh_public_key" {
  description = "SSH public key for container access"
  type        = string
}

variable "container_user" {
  description = "Default user for the container"
  type        = string
  default     = "debian"
}

# Container Features
variable "container_features" {
  description = "LXC container features"
  type        = string
  default     = "nesting=1,keyctl=1,fuse=1"
}

# Tags
variable "container_tags" {
  description = "Tags for the container"
  type        = string
  default     = "caddy,reverse-proxy,homelab"
}

# Technitium DNS Container Configuration
variable "technitium_name" {
  description = "Name of the Technitium DNS container"
  type        = string
  default     = "technitium-dns"
}

variable "technitium_id" {
  description = "Technitium DNS container ID"
  type        = number
  default     = 101
}

variable "technitium_cores" {
  description = "Number of CPU cores for Technitium DNS"
  type        = number
  default     = 2
}

variable "technitium_memory" {
  description = "Memory in MB for Technitium DNS"
  type        = number
  default     = 2048
}

variable "technitium_disk_size" {
  description = "Disk size in GB for Technitium DNS"
  type        = string
  default     = "10G"
}

variable "technitium_ip_address" {
  description = "Static IP address for Technitium DNS (CIDR notation)"
  type        = string
  default     = "192.168.1.101/24"
}

variable "technitium_tags" {
  description = "Tags for the Technitium DNS container"
  type        = string
  default     = "technitium,dns,ad-blocking,homelab"
}

# TinyAuth Container Configuration
variable "tinyauth_name" {
  description = "Name of the TinyAuth container"
  type        = string
  default     = "tinyauth"
}

variable "tinyauth_id" {
  description = "TinyAuth container ID"
  type        = number
  default     = 102
}

variable "tinyauth_cores" {
  description = "Number of CPU cores for TinyAuth"
  type        = number
  default     = 1
}

variable "tinyauth_memory" {
  description = "Memory in MB for TinyAuth"
  type        = number
  default     = 1024
}

variable "tinyauth_disk_size" {
  description = "Disk size in GB for TinyAuth"
  type        = string
  default     = "5G"
}

variable "tinyauth_ip_address" {
  description = "Static IP address for TinyAuth (CIDR notation)"
  type        = string
  default     = "192.168.1.102/24"
}

variable "tinyauth_tags" {
  description = "Tags for the TinyAuth container"
  type        = string
  default     = "tinyauth,authentication,auth-server,homelab"
}
