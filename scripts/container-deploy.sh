#!/bin/bash
# Quick Container Deployment Script for Hostinger VPS
# Deploy containers to any VPS with Docker installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
        print_warning "Secrets file not found: $SECRETS_FILE"
    fi
}

# Get VPS list for container deployment
list_vps() {
    print_status "Available VPS instances for container deployment:"

    if [ -z "$HOSTINGER_API_TOKEN" ]; then
        print_error "HOSTINGER_API_TOKEN not found. Please set it in $SECRETS_FILE"
        exit 1
    fi

    curl -s -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
         https://api.hostinger.com/v1/vps | \
    jq -r '.data[] | "\(.id): \(.hostname) (\(.ipv4_address)) - \(.status)"'
}

# Deploy Docker to existing VPS
setup_docker() {
    if [ -z "$1" ]; then
        print_error "Usage: $0 setup-docker <vps-ip>"
        exit 1
    fi

    VPS_IP="$1"
    print_status "Setting up Docker on VPS: $VPS_IP"

    # Create Docker setup script
    cat > /tmp/docker-setup.sh <<'SCRIPT'
#!/bin/bash
echo "🐳 Installing Docker and Docker Compose..."

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker user
useradd -m -s /bin/bash docker-user || true
usermod -aG docker docker-user
usermod -aG sudo docker-user

# Setup SSH for docker user
mkdir -p /home/docker-user/.ssh
cp /root/.ssh/authorized_keys /home/docker-user/.ssh/authorized_keys 2>/dev/null || true
chmod 700 /home/docker-user/.ssh
chmod 600 /home/docker-user/.ssh/authorized_keys
chown -R docker-user:docker-user /home/docker-user/.ssh

# Install Portainer
docker volume create portainer_data
docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "✅ Docker setup complete!"
echo "🎛️ Portainer: http://$(hostname -I | awk '{print $1}'):9000"
SCRIPT

    # Copy and execute setup script
    scp -o StrictHostKeyChecking=no /tmp/docker-setup.sh root@$VPS_IP:/tmp/
    ssh -o StrictHostKeyChecking=no root@$VPS_IP "chmod +x /tmp/docker-setup.sh && /tmp/docker-setup.sh"

    rm /tmp/docker-setup.sh

    print_success "Docker setup complete on $VPS_IP"
    print_status "Portainer available at: http://$VPS_IP:9000"
}

# Deploy container to VPS
deploy_container() {
    if [ $# -lt 3 ]; then
        print_error "Usage: $0 deploy <vps-ip> <container-name> <image> [port] [env-vars]"
        echo ""
        echo "Examples:"
        echo "  $0 deploy 1.2.3.4 my-nginx nginx:latest 80"
        echo "  $0 deploy 1.2.3.4 my-app node:18 3000 'NODE_ENV=production'"
        exit 1
    fi

    VPS_IP="$1"
    CONTAINER_NAME="$2"
    IMAGE="$3"
    PORT="$4"
    ENV_VARS="$5"

    print_status "Deploying container '$CONTAINER_NAME' to $VPS_IP"

    # Create deployment script
    cat > /tmp/deploy-container.sh <<SCRIPT
#!/bin/bash
set -e

CONTAINER_NAME="$CONTAINER_NAME"
IMAGE="$IMAGE"
PORT="$PORT"
ENV_VARS="$ENV_VARS"

# Check if container exists
if docker ps -a --format "table {{.Names}}" | grep -q "^\$CONTAINER_NAME\$"; then
    echo "⚠️ Container '\$CONTAINER_NAME' exists. Stopping and removing..."
    docker stop "\$CONTAINER_NAME" || true
    docker rm "\$CONTAINER_NAME" || true
fi

# Pull latest image
echo "📦 Pulling image: \$IMAGE"
docker pull "\$IMAGE"

# Build docker run command
DOCKER_CMD="docker run -d --name \$CONTAINER_NAME --restart unless-stopped"

# Add port mapping
if [ -n "\$PORT" ]; then
    DOCKER_CMD="\$DOCKER_CMD -p \$PORT:\$PORT"
fi

# Add environment variables
if [ -n "\$ENV_VARS" ]; then
    for env in \$ENV_VARS; do
        DOCKER_CMD="\$DOCKER_CMD -e \$env"
    done
fi

# Add image
DOCKER_CMD="\$DOCKER_CMD \$IMAGE"

echo "🚀 Running: \$DOCKER_CMD"
eval \$DOCKER_CMD

echo "✅ Container '\$CONTAINER_NAME' deployed successfully"
docker ps --filter "name=\$CONTAINER_NAME"

if [ -n "\$PORT" ]; then
    SERVER_IP=\$(hostname -I | awk '{print \$1}')
    echo "🌐 Access URL: http://\$SERVER_IP:\$PORT"
fi
SCRIPT

    # Execute deployment
    scp -o StrictHostKeyChecking=no /tmp/deploy-container.sh docker-user@$VPS_IP:/tmp/
    ssh -o StrictHostKeyChecking=no docker-user@$VPS_IP "chmod +x /tmp/deploy-container.sh && /tmp/deploy-container.sh"

    rm /tmp/deploy-container.sh

    print_success "Container deployed successfully!"
    if [ -n "$PORT" ]; then
        print_status "Access URL: http://$VPS_IP:$PORT"
    fi
    print_status "Portainer: http://$VPS_IP:9000"
}

# List containers on VPS
list_containers() {
    if [ -z "$1" ]; then
        print_error "Usage: $0 list <vps-ip>"
        exit 1
    fi

    VPS_IP="$1"
    print_status "Containers on $VPS_IP:"

    ssh -o StrictHostKeyChecking=no docker-user@$VPS_IP "docker ps -a"
}

# Stop container on VPS
stop_container() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        print_error "Usage: $0 stop <vps-ip> <container-name>"
        exit 1
    fi

    VPS_IP="$1"
    CONTAINER_NAME="$2"

    print_status "Stopping container '$CONTAINER_NAME' on $VPS_IP"
    ssh -o StrictHostKeyChecking=no docker-user@$VPS_IP "docker stop $CONTAINER_NAME"
    print_success "Container stopped"
}

# Start container on VPS
start_container() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        print_error "Usage: $0 start <vps-ip> <container-name>"
        exit 1
    fi

    VPS_IP="$1"
    CONTAINER_NAME="$2"

    print_status "Starting container '$CONTAINER_NAME' on $VPS_IP"
    ssh -o StrictHostKeyChecking=no docker-user@$VPS_IP "docker start $CONTAINER_NAME"
    print_success "Container started"
}

# Show container logs
show_logs() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        print_error "Usage: $0 logs <vps-ip> <container-name>"
        exit 1
    fi

    VPS_IP="$1"
    CONTAINER_NAME="$2"

    print_status "Logs for container '$CONTAINER_NAME' on $VPS_IP:"
    ssh -o StrictHostKeyChecking=no docker-user@$VPS_IP "docker logs $CONTAINER_NAME"
}

# Show help
show_help() {
    echo "Quick Container Deployment for Hostinger VPS"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list-vps                         List available VPS instances"
    echo "  setup-docker <vps-ip>           Install Docker on VPS"
    echo "  deploy <vps-ip> <name> <image> [port] [env]  Deploy container"
    echo "  list <vps-ip>                   List containers on VPS"
    echo "  stop <vps-ip> <container>       Stop container"
    echo "  start <vps-ip> <container>      Start container"
    echo "  logs <vps-ip> <container>       Show container logs"
    echo "  help                            Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 list-vps"
    echo "  $0 setup-docker 1.2.3.4"
    echo "  $0 deploy 1.2.3.4 my-nginx nginx:latest 80"
    echo "  $0 deploy 1.2.3.4 my-app node:18 3000 'NODE_ENV=production PORT=3000'"
    echo "  $0 list 1.2.3.4"
    echo "  $0 logs 1.2.3.4 my-nginx"
    echo ""
    echo "Prerequisites:"
    echo "  - SSH access to VPS"
    echo "  - HOSTINGER_API_TOKEN in config/secrets.env"
}

# Main script logic
main() {
    case "${1:-help}" in
        "list-vps")
            load_secrets
            list_vps
            ;;
        "setup-docker")
            setup_docker "$2"
            ;;
        "deploy")
            shift
            deploy_container "$@"
            ;;
        "list")
            list_containers "$2"
            ;;
        "stop")
            stop_container "$2" "$3"
            ;;
        "start")
            start_container "$2" "$3"
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run the main function
main "$@"
