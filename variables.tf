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

# VM Configuration Variables
variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "caddy-proxy"
}

variable "vm_id" {
  description = "VM ID"
  type        = number
  default     = 100
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "20G"
}

variable "vm_storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

# Network Configuration
variable "vm_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vm_ip_address" {
  description = "Static IP address for the VM (CIDR notation)"
  type        = string
  default     = "192.168.1.100/24"
}

variable "vm_gateway" {
  description = "Gateway IP address"
  type        = string
  default     = "192.168.1.1"
}

variable "vm_dns_servers" {
  description = "DNS servers"
  type        = string
  default     = "1.1.1.1 8.8.8.8"
}

# Cloud-init Configuration
variable "cloud_init_template" {
  description = "Cloud-init template ID"
  type        = number
  default     = 9000
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_user" {
  description = "Default user for the VM"
  type        = string
  default     = "debian"
}

# Tags
variable "vm_tags" {
  description = "Tags for the VM"
  type        = string
  default     = "caddy,reverse-proxy,homelab"
}
