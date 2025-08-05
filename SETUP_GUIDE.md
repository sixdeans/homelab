# Caddy Reverse Proxy Setup Guide

This guide provides detailed instructions for setting up a Caddy reverse proxy on Proxmox with Cloudflare SSL certificates for Mealie and Pi-hole services.

## Prerequisites Setup

### 1. Proxmox Configuration

#### Create a Debian Cloud-Init Template
```bash
# On your Proxmox server, create a Debian cloud-init template
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
qm create 9000 --name debian-cloud --net0 virtio,bridge=vmbr0
qm importdisk 9000 debian-12-generic-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

#### Create API Token
1. Log into Proxmox web interface
2. Go to Datacenter → Permissions → API Tokens
3. Click "Add" and create a token with these permissions:
   - VM.Allocate
   - VM.Clone
   - VM.Config.CDROM
   - VM.Config.CPU
   - VM.Config.Cloudinit
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
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

## Configuration

### 1. Terraform Variables

Copy and edit the Terraform variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your values:
```hcl
# Proxmox Configuration
proxmox_api_url          = "https://your-proxmox-ip:8006/api2/json"
proxmox_api_token_id     = "your-user@pam!your-token-name"
proxmox_api_token_secret = "your-token-secret"
proxmox_node             = "your-node-name"

# VM Configuration
vm_name      = "caddy-proxy"
vm_id        = 100
vm_cores     = 2
vm_memory    = 2048
vm_disk_size = "20G"
vm_storage   = "local-lvm"

# Network Configuration
vm_bridge      = "vmbr0"
vm_ip_address  = "192.168.1.100/24"
vm_gateway     = "192.168.1.1"
vm_dns_servers = "1.1.1.1 8.8.8.8"

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-actual-public-key"
vm_user        = "debian"
```

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

Update `ansible/inventory` with your VM IP:
```ini
[caddy_servers]
caddy-proxy ansible_host=192.168.1.100 ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_rsa
```

## Deployment

### Option 1: Automated Deployment
```bash
./deploy.sh
```

### Option 2: Manual Step-by-Step

#### Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

#### Configure Services
```bash
cd ansible
ansible-playbook -i inventory playbook.yml
```

## Verification

### 1. Check VM Status
```bash
# SSH into the VM
ssh debian@192.168.1.100

# Check Caddy service
sudo systemctl status caddy

# View Caddy logs
sudo journalctl -u caddy -f

# Test Caddy configuration
sudo caddy validate --config /etc/caddy/Caddyfile
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

#### 1. VM Creation Fails
- Check Proxmox API credentials
- Verify cloud-init template exists (ID 9000)
- Ensure sufficient resources available
- Check network bridge configuration

#### 2. SSH Connection Fails
- Verify SSH key is correct in terraform.tfvars
- Check VM IP address and network connectivity
- Ensure cloud-init has completed: `cloud-init status`

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
- Caddy access logs: `/var/log/caddy/access.log`
- Service-specific logs: `/var/log/caddy/mealie.log`, `/var/log/caddy/pihole.log`
- System logs: `journalctl -u caddy`
- UFW logs: `/var/log/ufw.log`

## Maintenance

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

#### Backup Caddy Configuration
```bash
# Backup configuration
sudo tar -czf caddy-backup-$(date +%Y%m%d).tar.gz /etc/caddy /var/lib/caddy

# Backup certificates (if needed)
sudo tar -czf caddy-certs-$(date +%Y%m%d).tar.gz /var/lib/caddy/.local/share/caddy
```

#### Recovery
```bash
# Restore configuration
sudo tar -xzf caddy-backup-YYYYMMDD.tar.gz -C /

# Restart service
sudo systemctl restart caddy
```

## Security Considerations

1. **Firewall**: UFW is configured to only allow necessary ports (22, 80, 443)
2. **SSL/TLS**: All traffic is encrypted with Cloudflare certificates
3. **Headers**: Security headers are automatically added
4. **User Permissions**: Caddy runs as non-root user
5. **Log Rotation**: Logs are automatically rotated to prevent disk space issues

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

## Support

For issues with this setup:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Verify all configuration values are correct
4. Test individual components (Proxmox, DNS, services)

For Caddy-specific issues, refer to the [official Caddy documentation](https://caddyserver.com/docs/).
