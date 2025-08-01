#!/bin/bash
# Terraform Automation Script for Hostinger Infrastructure
# Manages Git server deployment and infrastructure as code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TERRAFORM_DIR")"
SECRETS_FILE="$PROJECT_ROOT/config/secrets.env"

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

# Load environment variables
load_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        export $(cat "$SECRETS_FILE" | grep -v '^#' | xargs)
        print_success "Loaded secrets from $SECRETS_FILE"
    else
        print_error "Secrets file not found: $SECRETS_FILE"
        exit 1
    fi
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd "$TERRAFORM_DIR"

    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found, creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration"
    fi

    terraform init
    print_success "Terraform initialized"
}

# Plan infrastructure changes
plan_infrastructure() {
    print_status "Planning infrastructure changes..."
    cd "$TERRAFORM_DIR"

    # Export API token for Terraform
    export TF_VAR_hostinger_api_token="$HOSTINGER_API_TOKEN"

    terraform plan -out=tfplan
    print_success "Plan created: tfplan"
}

# Apply infrastructure changes
apply_infrastructure() {
    print_status "Applying infrastructure changes..."
    cd "$TERRAFORM_DIR"

    if [ ! -f "tfplan" ]; then
        print_error "No plan found. Run 'plan' first."
        exit 1
    fi

    terraform apply tfplan
    print_success "Infrastructure applied successfully"

    # Show outputs
    echo ""
    print_status "=== Infrastructure Outputs ==="
    terraform output
}

# Destroy infrastructure
destroy_infrastructure() {
    print_warning "This will destroy ALL infrastructure managed by Terraform!"
    read -p "Are you sure? (type 'yes' to confirm): " confirm

    if [ "$confirm" = "yes" ]; then
        print_status "Destroying infrastructure..."
        cd "$TERRAFORM_DIR"

        export TF_VAR_hostinger_api_token="$HOSTINGER_API_TOKEN"
        terraform destroy -auto-approve
        print_success "Infrastructure destroyed"
    else
        print_status "Destruction cancelled"
    fi
}

# Show infrastructure status
show_status() {
    print_status "Infrastructure Status:"
    cd "$TERRAFORM_DIR"

    if [ -f "terraform.tfstate" ]; then
        terraform show
        echo ""
        terraform output
    else
        print_warning "No infrastructure deployed yet"
    fi
}

# Show available resources
show_resources() {
    print_status "Querying available Hostinger resources..."
    cd "$TERRAFORM_DIR"

    export TF_VAR_hostinger_api_token="$HOSTINGER_API_TOKEN"

    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi

    # Plan to get data sources
    terraform plan -target=data.hostinger_vps_templates.all -target=data.hostinger_vps_data_centers.all -target=data.hostinger_vps_plans.all

    print_status "Available resources:"
    terraform output available_templates 2>/dev/null || echo "Templates: Not available (deploy first)"
    terraform output available_data_centers 2>/dev/null || echo "Data Centers: Not available (deploy first)"
    terraform output available_plans 2>/dev/null || echo "Plans: Not available (deploy first)"
}

# SSH to the Git server
ssh_to_server() {
    cd "$TERRAFORM_DIR"

    if [ ! -f "terraform.tfstate" ]; then
        print_error "No infrastructure deployed"
        exit 1
    fi

    SERVER_IP=$(terraform output -raw git_server_ip 2>/dev/null)

    if [ -z "$SERVER_IP" ]; then
        print_error "Could not get server IP"
        exit 1
    fi

    print_status "Connecting to Git server at $SERVER_IP..."
    ssh -o StrictHostKeyChecking=no root@"$SERVER_IP"
}

# Show help
show_help() {
    echo "Terraform Hostinger Infrastructure Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init        Initialize Terraform"
    echo "  plan        Plan infrastructure changes"
    echo "  apply       Apply infrastructure changes"
    echo "  destroy     Destroy all infrastructure"
    echo "  status      Show current infrastructure status"
    echo "  resources   Show available Hostinger resources"
    echo "  ssh         SSH to the Git server"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init     # Initialize Terraform"
    echo "  $0 plan     # Plan Git server deployment"
    echo "  $0 apply    # Deploy Git server"
    echo "  $0 ssh      # Connect to deployed server"
}

# Main script logic
main() {
    case "${1:-help}" in
        "init")
            load_secrets
            init_terraform
            ;;
        "plan")
            load_secrets
            plan_infrastructure
            ;;
        "apply")
            load_secrets
            apply_infrastructure
            ;;
        "destroy")
            load_secrets
            destroy_infrastructure
            ;;
        "status")
            show_status
            ;;
        "resources")
            load_secrets
            show_resources
            ;;
        "ssh")
            ssh_to_server
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run the main function
main "$@"
