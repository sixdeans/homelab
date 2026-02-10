# Quick Start Guide - Simplified Workflow

## Overview

Everything is now integrated into Terraform and Ansible - **no separate scripts needed!**

## What's Changed

✅ **SSH Setup is Automatic**: Terraform now automatically installs and configures SSH in all containers using `null_resource` provisioners
✅ **Single Command Deployment**: Just run `terraform apply` and everything is configured
✅ **No Manual Steps**: No need to run separate setup scripts

## Prerequisites

1. **SSH Keys**: Ensure you have SSH keys in WSL at `~/.ssh/id_ed25519`
2. **Proxmox Access**: You need SSH access to your Proxmox host as root
3. **Terraform & Ansible**: Both tools must be installed

## Quick Start

### From WSL:

```bash
cd /mnt/c/Users/Mathew/homelab

# Option 1: Full automated deployment
./deploy.sh

# Option 2: Step by step
terraform apply          # Creates containers + installs SSH automatically
cd ansible
ansible-playbook -i inventory playbook.yml  # Configures services
```

## What Happens During `terraform apply`

1. **Creates LXC containers** with proper network configuration
2. **Starts containers** automatically (`start = true`)
3. **Installs SSH** via `null_resource` provisioners:
   - Updates apt packages
   - Installs openssh-server
   - Enables and starts SSH service
   - Creates `.ssh` directory for debian user
   - Adds your public key to `authorized_keys`
   - Sets correct permissions
4. **Ready for Ansible** - SSH is configured and ready

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  terraform apply                                            │
│  ├─ Create containers                                       │
│  ├─ Start containers                                        │
│  └─ Setup SSH (null_resource)                              │
│     ├─ Install openssh-server                              │
│     ├─ Start SSH service                                   │
│     └─ Add SSH keys                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  ansible-playbook -i inventory playbook.yml                 │
│  ├─ Configure Caddy (reverse proxy)                        │
│  ├─ Configure Technitium (DNS server)                      │
│  └─ Configure TinyAuth (authentication)                    │
└─────────────────────────────────────────────────────────────┘
```

## Key Files

- **main.tf**: Contains container definitions + SSH setup via `null_resource`
- **terraform.tfvars**: Your configuration (IPs, credentials, etc.)
- **ansible/inventory**: Container IPs and SSH settings
- **ansible/playbook.yml**: Service configuration
- **deploy.sh**: Automated deployment script (runs both Terraform and Ansible)

## Troubleshooting

### If Terraform fails during SSH setup:

1. **Check Proxmox SSH access**:
   ```bash
   ssh root@192.168.50.200 "echo 'Connection OK'"
   ```

2. **Check container is running**:
   ```bash
   ssh root@192.168.50.200 "pct status 110"
   ```

3. **Manually verify SSH in container**:
   ```bash
   ssh root@192.168.50.200 "pct exec 110 -- systemctl status ssh"
   ```

### If Ansible fails to connect:

1. **Test SSH manually**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 debian@192.168.50.100 "echo 'SSH OK'"
   ```

2. **Check SSH key is correct**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Should match the key in terraform.tfvars
   ```

## Commands Reference

```bash
# Deploy everything
./deploy.sh

# Deploy only infrastructure (Terraform)
./deploy.sh infrastructure

# Configure only services (Ansible)
./deploy.sh configure

# Destroy infrastructure
./deploy.sh destroy

# Or manually:
terraform apply                              # Create + setup SSH
cd ansible && ansible-playbook -i inventory playbook.yml  # Configure
```

## Benefits of This Approach

✅ **No separate scripts** - everything in Terraform/Ansible
✅ **Declarative** - infrastructure as code
✅ **Idempotent** - safe to run multiple times
✅ **Automated** - SSH setup happens automatically
✅ **Clean** - no manual intervention needed

## Next Steps After Deployment

1. **Verify containers are running**:
   ```bash
   terraform output
   ```

2. **SSH into containers**:
   ```bash
   ssh debian@192.168.50.100  # Caddy
   ssh debian@192.168.1.101   # Technitium
   ssh debian@192.168.1.102   # TinyAuth
   ```

3. **Check services**:
   ```bash
   ssh debian@192.168.50.100 'sudo systemctl status caddy'
   ssh debian@192.168.1.101 'sudo systemctl status technitium-dns'
   ssh debian@192.168.1.102 'sudo systemctl status tinyauth'
   ```

## Important Notes

- **Proxmox SSH Access**: The `null_resource` provisioners need SSH access to your Proxmox host
- **SSH Keys**: Make sure your SSH keys are in WSL, not Windows
- **First Run**: The first `terraform apply` will prompt for Proxmox root password
- **Subsequent Runs**: Set up SSH keys for Proxmox root to avoid password prompts

## Setting Up Passwordless Proxmox Access (Optional)

To avoid entering Proxmox root password during Terraform runs:

```bash
# Copy your SSH key to Proxmox
ssh-copy-id root@192.168.50.200

# Test passwordless access
ssh root@192.168.50.200 "echo 'Passwordless SSH works!'"
```

Now `terraform apply` will run without password prompts!