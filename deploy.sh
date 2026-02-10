#!/bin/bash

# Caddy Reverse Proxy Deployment Script
# This script automates the deployment of Caddy reverse proxy infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v ssh &> /dev/null; then
        missing_tools+=("ssh")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to check if terraform.tfvars exists
check_terraform_vars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found"
        print_status "Copying terraform.tfvars.example to terraform.tfvars"
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your actual values before continuing"
        print_status "Required values to update:"
        echo "  - proxmox_api_url"
        echo "  - proxmox_api_token_id"
        echo "  - proxmox_api_token_secret"
        echo "  - ssh_public_key"
        echo "  - Network settings (IP, gateway, etc.)"
        read -p "Press Enter after updating terraform.tfvars to continue..."
    fi
}

# Function to check if Ansible variables are configured
check_ansible_vars() {
    if grep -q "example.com" ansible/group_vars/all.yml; then
        print_warning "Ansible variables contain default values"
        print_status "Please update ansible/group_vars/all.yml with your actual values:"
        echo "  - domain_name"
        echo "  - cloudflare_email"
        echo "  - cloudflare_api_token"
        echo "  - Service upstream addresses"
        read -p "Press Enter after updating ansible/group_vars/all.yml to continue..."
    fi
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo
    read -p "Do you want to apply this Terraform plan? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Terraform deployment cancelled"
        return 1
    fi
    
    # Apply deployment (this will also setup SSH via null_resource)
    print_status "Applying Terraform configuration..."
    print_status "Note: This will create containers and automatically setup SSH"
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Infrastructure deployed successfully"
    print_success "SSH has been automatically configured in all containers"
}

# Function to verify SSH connectivity
verify_ssh() {
    print_status "Verifying SSH connectivity to containers..."
    
    local caddy_ip=$(terraform output -raw container_ip_address 2>/dev/null || echo "192.168.50.100")
    local technitium_ip=$(terraform output -raw technitium_ip_address 2>/dev/null || echo "192.168.1.101")
    local tinyauth_ip=$(terraform output -raw tinyauth_ip_address 2>/dev/null || echo "192.168.1.102")
    
    print_status "Waiting for SSH services to be ready..."
    sleep 5
    
    # Test SSH connections
    if ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=5 -o StrictHostKeyChecking=no debian@$caddy_ip "echo 'SSH OK'" &>/dev/null; then
        print_success "✓ Caddy container SSH ready"
    else
        print_warning "⚠ Caddy container SSH not responding (may need more time)"
    fi
    
    if ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=5 -o StrictHostKeyChecking=no debian@$technitium_ip "echo 'SSH OK'" &>/dev/null; then
        print_success "✓ Technitium container SSH ready"
    else
        print_warning "⚠ Technitium container SSH not responding (may need more time)"
    fi
    
    if ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=5 -o StrictHostKeyChecking=no debian@$tinyauth_ip "echo 'SSH OK'" &>/dev/null; then
        print_success "✓ TinyAuth container SSH ready"
    else
        print_warning "⚠ TinyAuth container SSH not responding (may need more time)"
    fi
}

# Function to configure services with Ansible
configure_services() {
    print_status "Configuring services with Ansible..."
    
    # Verify SSH is ready
    verify_ssh
    
    # Run Ansible playbook
    print_status "Running Ansible playbook..."
    cd ansible
    ansible-playbook -i inventory playbook.yml -v
    cd ..
    
    print_success "Services configured successfully"
}

# Function to display deployment summary
show_summary() {
    print_success "Deployment completed successfully!"
    echo
    print_status "Deployment Summary:"
    echo "==================="
    
    local caddy_ip=$(terraform output -raw container_ip_address 2>/dev/null || echo "N/A")
    local technitium_ip=$(terraform output -raw technitium_ip_address 2>/dev/null || echo "N/A")
    local tinyauth_ip=$(terraform output -raw tinyauth_ip_address 2>/dev/null || echo "N/A")
    
    echo "Containers:"
    echo "- Caddy Proxy: $caddy_ip"
    echo "- Technitium DNS: $technitium_ip"
    echo "- TinyAuth: $tinyauth_ip"
    echo
    
    print_status "SSH Commands:"
    echo "- Caddy: ssh debian@$caddy_ip"
    echo "- Technitium: ssh debian@$technitium_ip"
    echo "- TinyAuth: ssh debian@$tinyauth_ip"
    echo
    
    print_status "Useful Commands:"
    echo "- Check Caddy status: ssh debian@$caddy_ip 'sudo systemctl status caddy'"
    echo "- Check Technitium status: ssh debian@$technitium_ip 'sudo systemctl status technitium'"
    echo "- Check TinyAuth status: ssh debian@$tinyauth_ip 'sudo systemctl status tinyauth'"
    echo ""
    print_status "Note: SSH is automatically configured by Terraform - no manual setup needed!"
}

# Main deployment function
main() {
    echo "========================================"
    echo "  Caddy Reverse Proxy Deployment"
    echo "========================================"
    echo
    
    check_prerequisites
    check_terraform_vars
    check_ansible_vars
    
    echo
    print_status "Starting deployment process..."
    
    if deploy_infrastructure; then
        if configure_services; then
            show_summary
        else
            print_error "Service configuration failed"
            exit 1
        fi
    else
        print_error "Infrastructure deployment failed"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "infrastructure")
        check_prerequisites
        check_terraform_vars
        deploy_infrastructure
        ;;
    "configure")
        check_prerequisites
        check_ansible_vars
        configure_services
        ;;
    "destroy")
        print_warning "This will destroy all infrastructure!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform destroy
        fi
        ;;
    *)
        main
        ;;
esac
