# Container Diagnostics Guide

## Issue: Connection timeout to containers

This means either:
1. Container is not running
2. SSH service is not installed/running in the container
3. Network connectivity issue

## Steps to Diagnose and Fix:

### Option 1: Check via Proxmox Web UI (Easiest)

1. Open Proxmox web UI: `https://192.168.50.200:8006`
2. Log in with your credentials
3. Check container status:
   - Look for containers 110 (caddy-proxy), 111 (technitium-dns), 112 (tinyauth)
   - Status should show "running" (green)
   - If stopped, right-click → Start

4. Check if SSH is installed:
   - Click on container 110 (caddy-proxy)
   - Click "Console" button
   - Login as root (no password needed from console)
   - Run: `apt-get update && apt-get install -y openssh-server`
   - Run: `systemctl enable ssh && systemctl start ssh`
   - Run: `systemctl status ssh` (should show "active (running)")

5. Add your SSH key manually:
   ```bash
   # In the container console (as root):
   mkdir -p /home/debian/.ssh
   chmod 700 /home/debian/.ssh
   
   # Paste your public key (get it from WSL with: cat ~/.ssh/id_ed25519.pub)
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDn+9eZuBB4e/u2lbfd5DQvC5pyN1SHSpz4Rit6RRE8" > /home/debian/.ssh/authorized_keys
   
   chmod 600 /home/debian/.ssh/authorized_keys
   chown -R debian:debian /home/debian/.ssh
   ```

6. Repeat steps 4-5 for containers 111 and 112

### Option 2: Use Terraform to Recreate (Recommended)

The cleanest solution is to destroy and recreate the containers with Terraform, which will properly configure everything:

```bash
# From WSL in the homelab directory
cd /mnt/c/Users/Mathew/homelab

# Destroy existing containers
terraform destroy -auto-approve

# Recreate with proper configuration
terraform apply -auto-approve

# Wait for containers to start (about 30 seconds)
sleep 30

# Test SSH connection
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes debian@192.168.50.100 "echo 'Success!'"
```

### Option 3: Manual Fix via Proxmox CLI

If you have SSH access to Proxmox root, you can run these commands:

```bash
# Check container status
pct status 110
pct status 111
pct status 112

# Start containers if stopped
pct start 110
pct start 111
pct start 112

# Install SSH in each container
pct exec 110 -- apt-get update
pct exec 110 -- apt-get install -y openssh-server
pct exec 110 -- systemctl enable ssh
pct exec 110 -- systemctl start ssh

# Add SSH key
pct exec 110 -- mkdir -p /home/debian/.ssh
pct exec 110 -- chmod 700 /home/debian/.ssh
pct exec 110 -- bash -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDn+9eZuBB4e/u2lbfd5DQvC5pyN1SHSpz4Rit6RRE8" > /home/debian/.ssh/authorized_keys'
pct exec 110 -- chmod 600 /home/debian/.ssh/authorized_keys
pct exec 110 -- chown -R debian:debian /home/debian/.ssh

# Repeat for containers 111 and 112
```

## Testing Connection

After fixing, test from WSL:

```bash
# Test Caddy container
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes debian@192.168.50.100 "echo 'Caddy OK'"

# Test Technitium container
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes debian@192.168.1.101 "echo 'Technitium OK'"

# Test TinyAuth container
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes debian@192.168.1.102 "echo 'TinyAuth OK'"
```

## Recommended Solution

**I recommend Option 2 (Terraform recreate)** because:
- It's the cleanest approach
- Ensures all configuration is correct
- Takes only a few minutes
- Containers will have SSH properly configured from the start
- The `start = true` parameter will ensure they start automatically

After recreating with Terraform, your Ansible playbook should work perfectly!