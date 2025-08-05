# Caddy Reverse Proxy Infrastructure

This project sets up a Caddy reverse proxy on Proxmox using Terraform and Ansible, with Cloudflare SSL certificates.

## Services Configured
- Mealie (meal planning application)
- Pi-hole (DNS ad blocker)

## Prerequisites

### Proxmox
- Proxmox VE server with API access
- User account with VM creation permissions
- Debian cloud-init template (create with `qm create 9000 --name debian-cloud --net0 virtio,bridge=vmbr0`)

### Cloudflare
- Cloudflare account with domain
- API token with Zone:Edit permissions

### Local Tools
- Terraform >= 1.0
- Ansible >= 2.9
- SSH key pair for VM access

## Quick Start

1. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Configure Caddy**
   ```bash
   cd ansible
   ansible-playbook -i inventory playbook.yml
   ```

## Configuration

### Terraform Variables
Edit `terraform.tfvars` with your specific values:
- Proxmox connection details
- VM specifications
- Network configuration

### Ansible Variables
Edit `ansible/group_vars/all.yml` with:
- Domain names
- Service endpoints
- Cloudflare API tokens

## File Structure
```
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Terraform variables
├── terraform.tfvars.example # Example variables
├── ansible/
│   ├── playbook.yml        # Main playbook
│   ├── inventory           # Ansible inventory
│   ├── group_vars/
│   │   └── all.yml         # Global variables
│   └── roles/
│       └── caddy/          # Caddy role
└── README.md
```

## Adding More Services

To add additional services to reverse proxy:
1. Add service configuration to `ansible/group_vars/all.yml`
2. Update the Caddyfile template in `ansible/roles/caddy/templates/Caddyfile.j2`
3. Run the Ansible playbook to apply changes

## Troubleshooting

### Common Issues
- **VM creation fails**: Check Proxmox permissions and template availability
- **SSL certificate issues**: Verify Cloudflare API token permissions
- **Service unreachable**: Check firewall rules and service status

### Logs
- Caddy logs: `journalctl -u caddy -f`
- Terraform state: `terraform show`
- Ansible verbose: `ansible-playbook -vvv`
