# Homelab Infrastructure

This project sets up a complete homelab infrastructure on Proxmox using Terraform and Ansible, including:
- Caddy reverse proxy with Cloudflare SSL certificates
- Technitium DNS Server for local DNS management
- TinyAuth authentication server

## Services Configured
- **Caddy Reverse Proxy**: Routes traffic to internal services with automatic SSL
- **Technitium DNS**: Local DNS server with web-based management
- **TinyAuth**: Lightweight authentication server for SSO and user management
- Mealie (meal planning application)

## Prerequisites

### Proxmox
- Proxmox VE server with API access
- User account with LXC container creation permissions
- Debian 13 LXC template (create with `pveam download local debian-13-standard_13.5-1_amd64.tar.zst`)

### Cloudflare
- Cloudflare account with domain
- API token with Zone:Edit permissions

### Local Tools
- Terraform >= 1.14.4
- Ansible >= 2.9
- SSH key pair for container access

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

3. **Configure Services**
   ```bash
   cd ansible
   # Deploy Caddy reverse proxy
   ansible-playbook -i inventory playbook.yml --tags caddy
   
   # Deploy Technitium DNS server
   ansible-playbook -i inventory playbook.yml --tags dns
   
   # Or deploy everything
   ansible-playbook -i inventory playbook.yml
   ```

## Configuration

### Terraform Variables
Edit `terraform.tfvars` with your specific values:
- Proxmox connection details
- LXC container specifications (CPU, memory, storage)
- Network configuration (static IP, gateway, DNS)
- Container features and settings

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
│       ├── caddy/          # Caddy reverse proxy role
│       ├── technitium/     # Technitium DNS role
│       └── tinyauth/       # TinyAuth authentication role
└── README.md
```

## Technitium DNS Server

### Features
- Web-based DNS management interface
- Support for DNS-over-HTTPS (DoH) and DNS-over-TLS (DoT)
- Built-in DHCP server
- DNS blocking and filtering
- Query logging and statistics
- Zone management and DNSSEC support

### Access
After deployment, access the Technitium DNS web interface at:
- **URL**: `http://<dns-server-ip>:5380`
- **Default credentials**: Set up on first login

### Configuration
The DNS server is configured with:
- **DNS Port**: 53 (UDP/TCP)
- **Web Interface Port**: 5380
- **Recursion**: Allowed for private networks only
- **Logging**: Enabled with 30-day retention

### Initial Setup
1. Access the web interface at `http://<dns-server-ip>:5380`
2. Complete the initial setup wizard
3. Set administrator password
4. Configure forwarders (optional)
5. Create DNS zones for your local network

### Common DNS Records
```bash
# Add A record
A record: hostname.local -> 192.168.1.x

# Add CNAME record
CNAME: service.local -> hostname.local

# Add PTR record for reverse DNS
PTR: x.1.168.192.in-addr.arpa -> hostname.local
```

## TinyAuth Authentication Server

### Features
- Lightweight authentication server
- User management and authentication
- Session management
- API-based authentication
- SQLite database for user storage
- Bcrypt password hashing

### Access
After deployment, TinyAuth runs internally on port 8080:
- **Internal URL**: `http://<auth-server-ip>:8080`
- **External Access**: Configure Caddy to proxy `auth.yourdomain.com` to this server

### Configuration
The authentication server is configured with:
- **Port**: 8080 (internal only)
- **Database**: SQLite at `/var/lib/tinyauth/tinyauth.db`
- **Session Timeout**: 1 hour
- **Security**: Bcrypt with 12 rounds

### Caddy Integration
Add to your Caddyfile on the Caddy server:
```
auth.yourdomain.com {
    reverse_proxy http://192.168.1.102:8080
}
```

### Initial Setup
1. The service starts automatically after deployment
2. Access via Caddy reverse proxy at `https://auth.yourdomain.com`
3. Use the TinyAuth API to create users and manage authentication
4. Integrate with your applications using the authentication API

### API Usage
```bash
# Create a user
curl -X POST http://192.168.1.102:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "secure_password"}'

# Authenticate
curl -X POST http://192.168.1.102:8080/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "secure_password"}'
```

## Adding More Services

To add additional services to reverse proxy:
1. Add service configuration to `ansible/group_vars/all.yml`
2. Update the Caddyfile template in `ansible/roles/caddy/templates/Caddyfile.j2`
3. Run the Ansible playbook to apply changes

## Troubleshooting

### Common Issues
- **Container creation fails**: Check Proxmox permissions and Debian 13 template availability
- **SSL certificate issues**: Verify Cloudflare API token permissions
- **Service unreachable**: Check firewall rules and service status
- **Container networking**: Verify IP configuration and bridge settings

### Logs
- Caddy logs: `journalctl -u caddy -f`
- Technitium DNS logs: `journalctl -u technitium-dns -f`
- TinyAuth logs: `journalctl -u tinyauth -f`
- Container logs: `pct exec <container-id> -- journalctl -f`
- Terraform state: `terraform show`
- Ansible verbose: `ansible-playbook -vvv`

### Technitium DNS Issues
- **Web interface not accessible**: Check if port 5380 is open and service is running
- **DNS queries not working**: Verify port 53 is open and firewall rules are correct
- **Service won't start**: Check logs with `journalctl -u technitium-dns -xe`
- **Configuration issues**: Review `/etc/technitium/config.json`

### TinyAuth Issues
- **Service not accessible**: Check if port 8080 is open and service is running
- **Authentication fails**: Verify database exists at `/var/lib/tinyauth/tinyauth.db`
- **Service won't start**: Check logs with `journalctl -u tinyauth -xe`
- **Configuration issues**: Review `/etc/tinyauth/config.yml`
- **Python errors**: Ensure virtual environment is properly set up at `/opt/tinyauth/venv`

### LXC Container Management
- List containers: `pct list`
- Start container: `pct start <container-id>`
- Stop container: `pct stop <container-id>`
- Enter container: `pct enter <container-id>`
- View container config: `pct config <container-id>`
