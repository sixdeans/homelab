# Quick Start Guide - Simplified Workflow

## Overview

Everything is now integrated into Terraform and Ansible - **no separate scripts needed!**

## What's Changed

✅ **SSH Setup is Automatic**: Terraform now automatically installs and configures SSH in all containers using `null_resource` provisioners
✅ **Single Command Deployment**: Just run `terraform apply` and everything is configured
✅ **No Manual Steps**: No need to run separate setup scripts
✅ **Fixed Services**: Technitium DNS and TinyAuth are now properly configured

## Prerequisites

1. **SSH Keys**: Ensure you have SSH keys in WSL at `~/.ssh/id_ed25519`
2. **Proxmox Access**: You need SSH access to your Proxmox host as root
3. **Terraform & Ansible**: Both tools must be installed
4. **Network**: Your network should be 192.168.50.x with gateway at 192.168.50.1

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

1. **Creates LXC containers** with proper network configuration (192.168.50.x)
2. **Starts containers** automatically (`start = true`)
3. **Installs SSH** via `null_resource` provisioners:
   - Updates apt packages
   - Installs openssh-server
   - Enables and starts SSH service
   - Creates `.ssh` directory for debian user
   - Adds your public key to `authorized_keys`
   - Sets correct permissions
4. **Ready for Ansible** - SSH is configured and ready

## Container Configuration

| Container | ID | IP Address | Port | Purpose |
|-----------|----|-----------| -----|---------|
| caddy-proxy | 110 | 192.168.50.100 | 80, 443 | Reverse proxy with SSL |
| technitium-dns | 111 | 192.168.50.101 | 53, 5380 | DNS server |
| tinyauth | 112 | 192.168.50.102 | 3000 | Authentication server |

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  terraform apply                                            │
│  ├─ Create containers (192.168.50.100-102)                 │
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
│  ├─ Configure Technitium (DNS server - .NET 9.0)          │
│  └─ Configure TinyAuth (authentication - Go binary)        │
└─────────────────────────────────────────────────────────────┘
```

## Key Fixes Applied

### Technitium DNS
- ✅ Changed .NET runtime from 10.0 to 9.0 (correct version)
- ✅ Fixed config.json path in systemd service
- ✅ Service now starts successfully

### TinyAuth
- ✅ Fixed repository URL (steveiliop56/tinyauth)
- ✅ Changed from Python to Go binary installation
- ✅ Fixed environment variable names (APP_URL, USERS, DATABASE_PATH)
- ✅ Used proper domain (https://auth.sixdeans.xyz) instead of localhost
- ✅ Fixed port number (3000)
- ✅ Service now starts successfully

## Key Files

- **main.tf**: Contains container definitions + SSH setup via `null_resource`
- **terraform.tfvars**: Your configuration (IPs, credentials, etc.)
- **ansible/inventory**: Container IPs (192.168.50.x) and SSH settings
- **ansible/playbook.yml**: Service configuration
- **deploy.sh**: Automated deployment script (runs both Terraform and Ansible)

## Troubleshooting

### If Terraform fails during SSH setup:

1. **Check Proxmox SSH access**:
   ```bash
   ssh root@192.168.50.1 "echo 'Connection OK'"
   ```

2. **Check container is running**:
   ```bash
   ssh root@192.168.50.1 "pct status 110"
   ```

3. **Manually verify SSH in container**:
   ```bash
   ssh root@192.168.50.1 "pct exec 110 -- systemctl status ssh"
   ```

### If Ansible fails to connect:

1. **Test SSH manually**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 debian@192.168.50.100 "echo 'SSH OK'"
   ssh -i ~/.ssh/id_ed25519 debian@192.168.50.101 "echo 'SSH OK'"
   ssh -i ~/.ssh/id_ed25519 debian@192.168.50.102 "echo 'SSH OK'"
   ```

2. **Check SSH key is correct**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Should match the key in terraform.tfvars
   ```

### Service-Specific Issues

#### Technitium DNS Not Starting
- Check .NET 9.0 is installed: `ssh debian@192.168.50.101 "dotnet --version"`
- View logs: `ssh debian@192.168.50.101 "sudo journalctl -u technitium-dns -n 50"`
- Verify config path: `ssh debian@192.168.50.101 "ls -la /etc/technitium/config.json"`

#### TinyAuth Not Starting
- Check .env file: `ssh debian@192.168.50.102 "cat /opt/tinyauth/.env"`
- Verify APP_URL is a proper domain (not localhost)
- View logs: `ssh debian@192.168.50.102 "sudo journalctl -u tinyauth -n 50"`
- Test manually: `ssh debian@192.168.50.102 "sudo -u tinyauth /opt/tinyauth/bin/tinyauth-start.sh"`

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
✅ **Fixed** - All known issues resolved

## Next Steps After Deployment

1. **Verify containers are running**:
   ```bash
   terraform output
   ```

2. **SSH into containers**:
   ```bash
   ssh debian@192.168.50.100  # Caddy
   ssh debian@192.168.50.101  # Technitium
   ssh debian@192.168.50.102  # TinyAuth
   ```

3. **Check services**:
   ```bash
   ssh debian@192.168.50.100 'sudo systemctl status caddy'
   ssh debian@192.168.50.101 'sudo systemctl status technitium-dns'
   ssh debian@192.168.50.102 'sudo systemctl status tinyauth'
   ```

4. **Access web interfaces**:
   - **Technitium DNS**: http://192.168.50.101:5380
   - **TinyAuth**: http://192.168.50.102:3000 (or https://auth.sixdeans.xyz via Caddy)
   - **Caddy**: Proxies your services via configured subdomains

## Default Credentials

### TinyAuth
- **Username**: admin
- **Password**: admin
- **Change immediately after first login!**

### Technitium DNS
- Set up during first access at http://192.168.50.101:5380

## Important Notes

- **Proxmox SSH Access**: The `null_resource` provisioners need SSH access to your Proxmox host
- **SSH Keys**: Make sure your SSH keys are in WSL, not Windows
- **First Run**: The first `terraform apply` will prompt for Proxmox root password
- **Subsequent Runs**: Set up SSH keys for Proxmox root to avoid password prompts
- **Network**: All containers use 192.168.50.x network
- **Gateway**: Must be set to 192.168.50.1 in terraform.tfvars

## Setting Up Passwordless Proxmox Access (Optional)

To avoid entering Proxmox root password during Terraform runs:

```bash
# Copy your SSH key to Proxmox
ssh-copy-id root@192.168.50.1

# Test passwordless access
ssh root@192.168.50.1 "echo 'Passwordless SSH works!'"
```

Now `terraform apply` will run without password prompts!

## Accessing Services

### Internal Access (from your network)
- Technitium DNS: http://192.168.50.101:5380
- TinyAuth: http://192.168.50.102:3000

### External Access (via Caddy reverse proxy)
- Configure DNS records pointing to 192.168.50.100
- Access via: https://auth.sixdeans.xyz
- Caddy handles SSL certificates automatically

## Monitoring

```bash
# Check all container statuses
ssh root@192.168.50.1 "pct list | grep -E '(110|111|112)'"

# View service logs
ssh debian@192.168.50.100 "sudo journalctl -u caddy -f"
ssh debian@192.168.50.101 "sudo journalctl -u technitium-dns -f"
ssh debian@192.168.50.102 "sudo journalctl -u tinyauth -f"
```
