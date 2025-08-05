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
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Infrastructure deployed successfully"
}

# Function to configure services with Ansible
configure_services() {
    print_status "Configuring services with Ansible..."
    
    # Wait for VM to be ready
    print_status "Waiting for VM to be ready..."
    sleep 30
    
    # Test SSH connectivity
    local vm_ip=$(terraform output -raw vm_ip_address)
    print_status "Testing SSH connectivity to $vm_ip..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no debian@$vm_ip "echo 'SSH connection successful'" &> /dev/null; then
            print_success "SSH connection established"
            break
        else
            print_status "SSH attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Failed to establish SSH connection after $max_attempts attempts"
        return 1
    fi
    
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
    
    local vm_ip=$(terraform output -raw vm_ip_address)
    local vm_name=$(terraform output -raw vm_name)
    
    echo "VM Name: $vm_name"
    echo "VM IP: $vm_ip"
    echo "SSH Command: $(terraform output -raw ssh_connection)"
    echo
    
    print_status "Configured Services:"
    echo "- Mealie: https://mealie.$(grep domain_name ansible/group_vars/all.yml | cut -d'"' -f2)"
    echo "- Pi-hole: https://pihole.$(grep domain_name ansible/group_vars/all.yml | cut -d'"' -f2)"
    echo "- Health Check: https://health.$(grep domain_name ansible/group_vars/all.yml | cut -d'"' -f2)"
    echo
    
    print_status "Next Steps:"
    echo "1. Update your DNS records to point to $vm_ip"
    echo "2. Verify SSL certificates are working"
    echo "3. Test your services through the reverse proxy"
    echo
    
    print_status "Useful Commands:"
    echo "- Check Caddy status: ssh debian@$vm_ip 'sudo systemctl status caddy'"
    echo "- View Caddy logs: ssh debian@$vm_ip 'sudo journalctl -u caddy -f'"
    echo "- Reload Caddy config: ssh debian@$vm_ip 'sudo systemctl reload caddy'"
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
