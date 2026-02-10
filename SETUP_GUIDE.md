# Homelab Infrastructure Setup Guide

This guide provides detailed instructions for setting up a complete homelab infrastructure on Proxmox with three LXC containers: Caddy reverse proxy, Technitium DNS server, and TinyAuth authentication server.

## Prerequisites Setup

### 1. Proxmox Configuration

#### Download LXC Template
```bash
# On your Proxmox server, download the Debian 13 LXC template
pveam update
pveam available | grep debian-13
pveam download local debian-13-standard_13.1-2_amd64.tar.zst
```

#### Verify Template
```bash
# List available templates
pveam list local
```

#### Create API Token
1. Log into Proxmox web interface
2. Go to Datacenter → Permissions → API Tokens
3. Click "Add" and create a token with these permissions:
   - VM.Allocate
   - VM.Clone
   - VM.Config.CDROM
   - VM.Config.CPU
   - VM.Config.Disk
   - VM.Config.HWType
   - VM.Config.Memory
   - VM.Config.Network
   - VM.Config.Options
   - VM.Monitor
   - VM.Audit
   - VM.PowerMgmt
   - Datastore.AllocateSpace
   - Datastore.Audit
   - **For LXC containers, also add:**
     - Sys.Modify
     - Sys.Console

### 2. Cloudflare Configuration

#### Get API Token
1. Log into Cloudflare dashboard
2. Go to My Profile → API Tokens
3. Create token with these permissions:
   - Zone:Zone:Read
   - Zone:DNS:Edit
4. Include your domain in Zone Resources

#### DNS Records (Optional - can be done manually)
You'll need to create A records pointing to your Caddy server:
- `mealie.yourdomain.com` → `192.168.1.100`
- `pihole.yourdomain.com` → `192.168.1.100`
- `health.yourdomain.com` → `192.168.1.100`

### 3. SSH Key Setup

Generate SSH key pair if you don't have one:
```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Or RSA key (alternative)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

**Note:** The public key will be at `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`

## Configuration

### 1. Terraform Variables

Copy and edit the Terraform variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your values:
```hcl
# Proxmox Configuration
proxmox_api_url          = "https://192.168.50.200:8006/api2/json"
proxmox_api_token_id     = "root@pam!iac_token"
proxmox_api_token_secret = "your-token-secret"
proxmox_node             = "pve"

# Caddy Container Configuration
container_name     = "caddy-proxy"
container_id       = 110
container_cores    = 2
container_memory   = 1024
container_disk_size = "10G"
container_storage  = "local-lvm"

# Network Configuration
container_bridge     = "vmbr0"
container_ip_address = "192.168.50.100/24"
container_gateway    = "192.168.50.200"  # IMPORTANT: Must match your network gateway
container_dns_servers = "1.1.1.1 8.8.8.8"

# Technitium DNS Container Configuration
technitium_name     = "technitium-dns"
technitium_id       = 111
technitium_cores    = 2
technitium_memory   = 2048
technitium_disk_size = "10G"
technitium_ip_address = "192.168.1.101/24"

# TinyAuth Container Configuration
tinyauth_name     = "tinyauth"
tinyauth_id       = 112
tinyauth_cores    = 1
tinyauth_memory   = 1024
tinyauth_disk_size = "5G"
tinyauth_ip_address = "192.168.1.102/24"

# SSH Configuration
ssh_public_key = "ssh-ed25519 AAAAB3NzaC1... your-actual-public-key"
container_user = "debian"
```

**Important Notes:**
- `container_gateway` must be set correctly for network connectivity
- All containers will automatically start when created (no manual start needed)
- Container IDs must be unique and not conflict with existing containers

### 2. Ansible Variables

Edit `ansible/group_vars/all.yml`:
```yaml
# Domain Configuration
domain_name: "yourdomain.com"
cloudflare_email: "your-email@yourdomain.com"
cloudflare_api_token: "your-cloudflare-api-token"

# Service Configuration
services:
  mealie:
    subdomain: "mealie"
    upstream: "192.168.1.101:9925"  # Your Mealie server
    description: "Meal planning application"
  
  pihole:
    subdomain: "pihole"
    upstream: "192.168.1.102:80"   # Your Pi-hole server
    description: "DNS ad blocker admin interface"
```

### 3. Ansible Inventory

Update `ansible/inventory` with your container IPs:
```ini
[caddy_servers]
caddy-proxy ansible_host=192.168.50.100 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_ed25519

[caddy_servers:vars]
ansible_python_interpreter=/usr/bin/python3

[dns_servers]
technitium-dns ansible_host=192.168.1.101 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_ed25519

[dns_servers:vars]
ansible_python_interpreter=/usr/bin/python3

[auth_servers]
tinyauth ansible_host=192.168.1.102 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_ed25519

[auth_servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Important:** Make sure the IP addresses match your `terraform.tfvars` configuration.

## Deployment

### Automated Deployment (Recommended)

Everything is now fully automated - Terraform handles container creation, starting, AND SSH setup!

```bash
# From WSL - Full deployment
cd /mnt/c/Users/Mathew/homelab
./deploy.sh

# Or step by step:
./deploy.sh infrastructure  # Creates containers + installs SSH automatically
./deploy.sh configure       # Runs Ansible configuration
```

### Manual Step-by-Step

#### Deploy Infrastructure with Terraform
```bash
# Initialize Terraform
terraform init

# Upgrade to latest provider version (if needed)
terraform init -upgrade

# Plan deployment
terraform plan

# Apply configuration
# This will: create containers, start them, AND setup SSH automatically
terraform apply
```

**Note**: The `terraform apply` command now automatically:
- Creates LXC containers
- Starts containers (`start = true`)
- Installs SSH via `null_resource` provisioners
- Configures SSH keys for debian user

#### Configure Services with Ansible
```bash
cd ansible
ansible-playbook -i inventory playbook.yml -v
```

**No manual SSH setup needed!** Everything is handled by Terraform.

## Verification

### 1. Check Container Status
```bash
# Check all containers from Proxmox host
ssh root@192.168.50.200 "pct list | grep -E '(110|111|112)'"

# Check individual container status
ssh root@192.168.50.200 "pct status 110"  # Caddy
ssh root@192.168.50.200 "pct status 111"  # Technitium
ssh root@192.168.50.200 "pct status 112"  # TinyAuth
```

### 2. Check Services
```bash
# SSH into Caddy container
ssh debian@192.168.50.100

# Check Caddy service
sudo systemctl status caddy

# View Caddy logs
sudo journalctl -u caddy -f

# SSH into Technitium container
ssh debian@192.168.1.101
sudo systemctl status technitium

# SSH into TinyAuth container
ssh debian@192.168.1.102
sudo systemctl status tinyauth
```

### 2. Test Services
```bash
# Test health endpoint
curl -k https://health.yourdomain.com

# Test service endpoints
curl -k https://mealie.yourdomain.com
curl -k https://pihole.yourdomain.com
```

### 3. Check SSL Certificates
```bash
# Check certificate details
openssl s_client -connect mealie.yourdomain.com:443 -servername mealie.yourdomain.com
```

## Troubleshooting

### Common Issues

#### 1. Container Creation Fails
**Error:** `volume 'local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst' does not exist`
- **Solution:** Download the LXC template first:
  ```bash
  ssh root@192.168.50.200 "pveam download local debian-13-standard_13.1-2_amd64.tar.zst"
  ```

#### 2. Terraform SSH Setup Fails
**Error:** `null_resource` provisioner fails during SSH installation
- **Cause:** Cannot connect to Proxmox host
- **Solution:** Verify SSH access to Proxmox:
  ```bash
  ssh root@192.168.50.200 "echo 'Connection OK'"
  ```
- **Optional:** Set up passwordless SSH to Proxmox:
  ```bash
  ssh-copy-id root@192.168.50.200
  ```

#### 3. SSH Connection Fails After Terraform
**Error:** `dial tcp 192.168.50.100:22: connect: no route to host`
- **Cause:** Missing gateway configuration
- **Solution:** Ensure `container_gateway` is set in `terraform.tfvars`
- **Verify:** Check container can reach gateway:
  ```bash
  ssh root@192.168.50.200 "pct exec 110 -- ping -c 3 192.168.50.200"
  ```

#### 4. Ansible Connection Fails
**Error:** Ansible cannot connect to containers
- **Check 1:** Verify Terraform completed successfully (SSH should be installed)
- **Check 2:** Test SSH manually from WSL:
  ```bash
  ssh -i ~/.ssh/id_ed25519 debian@192.168.50.100 "echo 'SSH OK'"
  ```
- **Check 3:** Verify IP addresses match in `ansible/inventory` and `terraform.tfvars`
- **Check 4:** Verify SSH key in terraform.tfvars matches your actual key:
  ```bash
  cat ~/.ssh/id_ed25519.pub
  ```

#### 5. Network Connectivity Issues
- **Check gateway:** Containers need gateway to route traffic
- **Check DNS:** Verify `container_dns_servers` is set correctly
- **Test connectivity:**
  ```bash
  ssh debian@192.168.50.100 "ping -c 3 8.8.8.8"
  ssh debian@192.168.50.100 "ping -c 3 google.com"
  ```

#### 6. Proxmox Password Prompts During Terraform
**Issue:** Terraform keeps asking for Proxmox root password
- **Solution:** Set up SSH key authentication to Proxmox:
  ```bash
  ssh-copy-id root@192.168.50.200
  ```
- **Verify:** Test passwordless access:
  ```bash
  ssh root@192.168.50.200 "echo 'Passwordless SSH works!'"
  ```

#### 3. Caddy Service Issues
```bash
# Check service status
sudo systemctl status caddy

# View detailed logs
sudo journalctl -u caddy -n 50

# Test configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload configuration
sudo systemctl reload caddy
```

#### 4. SSL Certificate Issues
- Verify Cloudflare API token permissions
- Check DNS propagation: `dig mealie.yourdomain.com`
- Review Caddy logs for ACME errors
- Ensure Cloudflare proxy is disabled for the records

#### 5. Service Unreachable
- Check upstream service status
- Verify firewall rules: `sudo ufw status`
- Test direct connection to upstream services
- Check Caddy access logs: `sudo tail -f /var/log/caddy/access.log`

### Log Locations
- **Caddy logs:** `ssh debian@192.168.50.100 "sudo journalctl -u caddy -f"`
- **Technitium logs:** `ssh debian@192.168.1.101 "sudo journalctl -u technitium -f"`
- **TinyAuth logs:** `ssh debian@192.168.1.102 "sudo journalctl -u tinyauth -f"`
- **Container logs (from Proxmox):** `ssh root@192.168.50.200 "pct exec 110 -- journalctl -n 50"`
- **Terraform logs:** Check terminal output during `terraform apply`

### Useful Commands
```bash
# View Terraform outputs
terraform output

# Check container status from Proxmox
ssh root@192.168.50.200 "pct list | grep -E '(110|111|112)'"

# Restart a container
ssh root@192.168.50.200 "pct restart 110"

# Enter container console
ssh root@192.168.50.200 "pct enter 110"

# View container configuration
ssh root@192.168.50.200 "pct config 110"

# Verify SSH is installed in container
ssh root@192.168.50.200 "pct exec 110 -- systemctl status ssh"

# Test SSH connection to container
ssh -i ~/.ssh/id_ed25519 debian@192.168.50.100 "echo 'SSH OK'"
```

## Maintenance

### Starting/Stopping Containers

```bash
# Start containers (they auto-start on boot with onboot=true)
ssh root@192.168.50.200 "pct start 110"  # Caddy
ssh root@192.168.50.200 "pct start 111"  # Technitium
ssh root@192.168.50.200 "pct start 112"  # TinyAuth

# Stop containers
ssh root@192.168.50.200 "pct stop 110"  # Caddy
ssh root@192.168.50.200 "pct stop 111"  # Technitium
ssh root@192.168.50.200 "pct stop 112"  # TinyAuth

# Restart containers
ssh root@192.168.50.200 "pct restart 110"
ssh root@192.168.50.200 "pct restart 111"
ssh root@192.168.50.200 "pct restart 112"
```

**Note:** Containers are configured with `onboot = true` and `start = true`, so they automatically start when created and when Proxmox boots.

### Adding New Services

1. Update `ansible/group_vars/all.yml`:
```yaml
services:
  # ... existing services ...
  newservice:
    subdomain: "newservice"
    upstream: "192.168.1.103:8080"
    description: "New service description"
```

2. Run Ansible playbook:
```bash
cd ansible
ansible-playbook -i inventory playbook.yml --tags configure
```

### Updating Caddy Configuration

1. Edit templates in `ansible/roles/caddy/templates/`
2. Run configuration update:
```bash
cd ansible
ansible-playbook -i inventory playbook.yml --tags configure
```

### Backup and Recovery

#### Backup Containers
```bash
# Backup container (from Proxmox host)
ssh root@192.168.50.200 "vzdump 110 --mode snapshot --storage local"

# Backup all homelab containers
ssh root@192.168.50.200 "vzdump 110 111 112 --mode snapshot --storage local"
```

#### Backup Configuration Files
```bash
# Backup Caddy configuration
ssh debian@192.168.50.100 "sudo tar -czf /tmp/caddy-backup-$(date +%Y%m%d).tar.gz /etc/caddy"
scp debian@192.168.50.100:/tmp/caddy-backup-*.tar.gz ./backups/

# Backup Technitium configuration
ssh debian@192.168.1.101 "sudo tar -czf /tmp/technitium-backup-$(date +%Y%m%d).tar.gz /etc/technitium"
scp debian@192.168.1.101:/tmp/technitium-backup-*.tar.gz ./backups/
```

#### Recovery
```bash
# Restore from Proxmox backup
ssh root@192.168.50.200 "pct restore 110 /var/lib/vz/dump/vzdump-lxc-110-*.tar.zst"

# Restore configuration
scp ./backups/caddy-backup-*.tar.gz debian@192.168.50.100:/tmp/
ssh debian@192.168.50.100 "sudo tar -xzf /tmp/caddy-backup-*.tar.gz -C /"
ssh debian@192.168.50.100 "sudo systemctl restart caddy"
```

## Security Considerations

1. **Firewall**: UFW is configured to only allow necessary ports (22, 80, 443)
2. **SSL/TLS**: All traffic is encrypted with Cloudflare certificates
3. **Headers**: Security headers are automatically added
4. **User Permissions**: Services run as non-root users
5. **Log Rotation**: Logs are automatically rotated to prevent disk space issues
6. **Container Isolation**: LXC containers provide namespace isolation
7. **Unprivileged Containers**: All containers run in unprivileged mode for enhanced security
8. **SSH Keys**: Only key-based authentication is enabled (no password auth)

## Performance Tuning

### For High Traffic
Edit `ansible/group_vars/all.yml` and add:
```yaml
caddy_performance:
  max_connections: 1000
  read_timeout: "30s"
  write_timeout: "30s"
  idle_timeout: "120s"
```

### Resource Monitoring
```bash
# Monitor resource usage
htop
iotop
netstat -tulpn
```

## Quick Reference

### Container Information
| Container | ID | IP Address | Purpose |
|-----------|----|-----------| --------|
| caddy-proxy | 110 | 192.168.50.100 | Reverse proxy with SSL |
| technitium-dns | 111 | 192.168.1.101 | DNS server with ad-blocking |
| tinyauth | 112 | 192.168.1.102 | Authentication server |

### Important Files
- **Terraform config:** `main.tf` (includes SSH setup via null_resource), `variables.tf`, `terraform.tfvars`
- **Ansible inventory:** `ansible/inventory`
- **Ansible playbook:** `ansible/playbook.yml`
- **Deploy script:** `deploy.sh` (automated deployment)
- **Quick start guide:** `QUICK_START.md` (simplified workflow guide)

### Common Commands
```bash
# Deploy everything (Terraform + Ansible)
./deploy.sh

# Deploy only infrastructure (creates containers + SSH)
./deploy.sh infrastructure

# Configure only services (Ansible)
./deploy.sh configure

# Manual deployment
terraform apply                                    # Creates + SSH setup
cd ansible && ansible-playbook -i inventory playbook.yml  # Configure

# Check Terraform outputs
terraform output

# Destroy infrastructure
terraform destroy
```

### New Automated Features
✅ **SSH Auto-Install**: Terraform automatically installs SSH in containers
✅ **Auto-Start**: Containers start automatically when created
✅ **SSH Key Setup**: Your public key is automatically added to containers
✅ **No Manual Steps**: Everything is handled by Terraform and Ansible

## Support

For issues with this setup:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Verify all configuration values are correct
4. Test individual components (Proxmox, containers, network, services)
5. Verify Terraform completed successfully (check for null_resource errors)
6. See **QUICK_START.md** for simplified workflow guide

For component-specific issues:
- **Caddy:** [Official Caddy Documentation](https://caddyserver.com/docs/)
- **Technitium:** [Technitium DNS Documentation](https://technitium.com/dns/)
- **Proxmox LXC:** [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)
- **Terraform Proxmox Provider:** [Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

## Additional Resources

- **QUICK_START.md**: Simplified workflow guide with the new automated setup
- **README.md**: Project overview and architecture
- **deploy.sh**: Automated deployment script with built-in checks
