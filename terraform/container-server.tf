# Container Server Infrastructure for Hostinger VPS
# Deploy Docker containers with comprehensive management capabilities

# SSH Key for container server access
resource "hostinger_vps_ssh_key" "container_server_key" {
  name = "Container Server SSH Key"
  key  = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
}

# Post-install script for container server setup
resource "hostinger_vps_post_install_script" "container_server_setup" {
  name    = "Container Server Setup Script"
  content = <<-EOT
    #!/bin/bash
    # Automated Container Server Setup via Terraform
    # Full Docker + Docker Compose + Portainer setup

    echo "🐳 Starting container server setup via Terraform..."

    # Update system
    apt update && apt upgrade -y

    # Install required packages
    apt install -y curl wget git nginx fail2ban ufw htop tree jq unzip

    # Install Docker
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose
    echo "🔧 Installing Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
    curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    # Create docker user and add to docker group
    useradd -m -s /bin/bash docker-user || true
    usermod -aG docker docker-user
    usermod -aG sudo docker-user

    # Setup SSH directory for docker user
    mkdir -p /home/docker-user/.ssh
    cp /root/.ssh/authorized_keys /home/docker-user/.ssh/authorized_keys
    chmod 700 /home/docker-user/.ssh
    chmod 600 /home/docker-user/.ssh/authorized_keys
    chown -R docker-user:docker-user /home/docker-user/.ssh

    # Create container projects directory
    mkdir -p /home/docker-user/containers
    mkdir -p /home/docker-user/containers/templates
    mkdir -p /home/docker-user/containers/projects
    chown -R docker-user:docker-user /home/docker-user/containers

    # Setup firewall
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 9000    # Portainer
    ufw allow 8080    # Alternative web port
    ufw allow 3000    # Development servers
    ufw allow 5000    # Flask/Python apps
    ufw allow 8000    # Django/FastAPI
    ufw --force enable
    echo "✅ Firewall configured for containers"

    # Install Portainer for container management
    echo "🎛️ Installing Portainer..."
    docker volume create portainer_data
    docker run -d \
      --name portainer \
      --restart unless-stopped \
      -p 9000:9000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest

    # Create container management scripts
    cat > /home/docker-user/deploy-container.sh <<'SCRIPT'
#!/bin/bash
# Deploy a container from Docker Hub or custom image

if [ $# -lt 2 ]; then
    echo "Usage: $0 <container-name> <image> [port] [environment-file]"
    echo "Examples:"
    echo "  $0 my-nginx nginx:latest 80"
    echo "  $0 my-app node:18 3000 .env"
    echo "  $0 database postgres:15 5432 postgres.env"
    exit 1
fi

CONTAINER_NAME="$1"
IMAGE="$2"
PORT="$3"
ENV_FILE="$4"

# Check if container already exists
if docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "❌ Container '$CONTAINER_NAME' already exists"
    echo "Use: docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME to remove it first"
    exit 1
fi

# Build docker run command
DOCKER_CMD="docker run -d --name $CONTAINER_NAME --restart unless-stopped"

# Add port mapping if specified
if [ -n "$PORT" ]; then
    DOCKER_CMD="$DOCKER_CMD -p $PORT:$PORT"
fi

# Add environment file if specified
if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
    DOCKER_CMD="$DOCKER_CMD --env-file $ENV_FILE"
fi

# Add image
DOCKER_CMD="$DOCKER_CMD $IMAGE"

echo "🚀 Deploying container: $CONTAINER_NAME"
echo "📦 Image: $IMAGE"
echo "🔧 Command: $DOCKER_CMD"

# Run the container
eval $DOCKER_CMD

if [ $? -eq 0 ]; then
    echo "✅ Container '$CONTAINER_NAME' deployed successfully"
    echo "📊 Status:"
    docker ps --filter "name=$CONTAINER_NAME"

    if [ -n "$PORT" ]; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo "🌐 Access URL: http://$SERVER_IP:$PORT"
    fi
else
    echo "❌ Failed to deploy container '$CONTAINER_NAME'"
    exit 1
fi
SCRIPT

    chmod +x /home/docker-user/deploy-container.sh

    # Create Docker Compose template
    cat > /home/docker-user/containers/templates/docker-compose.yml <<'COMPOSE'
version: '3.8'

services:
  # Example web application
  webapp:
    image: nginx:latest
    container_name: webapp
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - app-network

  # Example database
  database:
    image: postgres:15
    container_name: database
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: ${var.postgres_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network
    ports:
      - "5432:5432"

  # Example Redis cache
  cache:
    image: redis:7-alpine
    container_name: cache
    restart: unless-stopped
    networks:
      - app-network
    ports:
      - "6379:6379"

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
COMPOSE

    # Create project deployment script
    cat > /home/docker-user/deploy-project.sh <<'PROJECT'
#!/bin/bash
# Deploy a project using Docker Compose

if [ -z "$1" ]; then
    echo "Usage: $0 <project-directory>"
    echo "Project directory should contain docker-compose.yml"
    exit 1
fi

PROJECT_DIR="$1"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory '$PROJECT_DIR' not found"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found in '$PROJECT_DIR'"
    exit 1
fi

echo "🚀 Deploying project: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Pull latest images
docker-compose pull

# Deploy the project
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✅ Project deployed successfully"
    echo "📊 Status:"
    docker-compose ps

    echo "🌐 Access URLs:"
    docker-compose config --services | while read service; do
        ports=$(docker-compose port $service 80 2>/dev/null || docker-compose port $service 3000 2>/dev/null || docker-compose port $service 8080 2>/dev/null)
        if [ -n "$ports" ]; then
            SERVER_IP=$(hostname -I | awk '{print $1}')
            port=$(echo $ports | cut -d: -f2)
            echo "  $service: http://$SERVER_IP:$port"
        fi
    done
else
    echo "❌ Failed to deploy project"
    exit 1
fi
PROJECT

    chmod +x /home/docker-user/deploy-project.sh

    # Create container management helper
    cat > /home/docker-user/container-manager.sh <<'MANAGER'
#!/bin/bash
# Container Management Helper

show_help() {
    echo "Container Management Helper"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  list      Show all containers"
    echo "  running   Show running containers"
    echo "  images    Show available images"
    echo "  stats     Show container resource usage"
    echo "  logs      Show container logs"
    echo "  stop      Stop a container"
    echo "  start     Start a container"
    echo "  restart   Restart a container"
    echo "  remove    Remove a container"
    echo "  cleanup   Remove unused containers and images"
    echo "  update    Update all containers"
}

case "$1" in
    "list")
        echo "📦 All containers:"
        docker ps -a
        ;;
    "running")
        echo "🏃 Running containers:"
        docker ps
        ;;
    "images")
        echo "🖼️ Available images:"
        docker images
        ;;
    "stats")
        echo "📊 Container resource usage:"
        docker stats --no-stream
        ;;
    "logs")
        if [ -z "$2" ]; then
            echo "Usage: $0 logs <container-name>"
            exit 1
        fi
        echo "📋 Logs for container: $2"
        docker logs "$2"
        ;;
    "stop")
        if [ -z "$2" ]; then
            echo "Usage: $0 stop <container-name>"
            exit 1
        fi
        echo "⏹️ Stopping container: $2"
        docker stop "$2"
        ;;
    "start")
        if [ -z "$2" ]; then
            echo "Usage: $0 start <container-name>"
            exit 1
        fi
        echo "▶️ Starting container: $2"
        docker start "$2"
        ;;
    "restart")
        if [ -z "$2" ]; then
            echo "Usage: $0 restart <container-name>"
            exit 1
        fi
        echo "🔄 Restarting container: $2"
        docker restart "$2"
        ;;
    "remove")
        if [ -z "$2" ]; then
            echo "Usage: $0 remove <container-name>"
            exit 1
        fi
        echo "🗑️ Removing container: $2"
        docker stop "$2" 2>/dev/null
        docker rm "$2"
        ;;
    "cleanup")
        echo "🧹 Cleaning up unused containers and images..."
        docker container prune -f
        docker image prune -f
        docker volume prune -f
        docker network prune -f
        ;;
    "update")
        echo "🔄 Updating all containers..."
        docker images --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | while read image; do
            echo "Pulling $image..."
            docker pull "$image"
        done
        ;;
    *)
        show_help
        ;;
esac
MANAGER

    chmod +x /home/docker-user/container-manager.sh

    # Setup Nginx for container proxy and management interface
    cat > /etc/nginx/sites-available/containers <<EOF
server {
    listen 80 default_server;
    server_name containers.* ${var.container_server_hostname};

    # Portainer proxy
    location /portainer/ {
        proxy_pass http://localhost:9000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Container status dashboard
    location / {
        alias /var/www/containers/;
        index index.html;
        try_files \$uri \$uri/ =404;
    }

    # Health check endpoint
    location /health {
        return 200 'Container server is running - Deployed via Terraform';
        add_header Content-Type text/plain;
    }

    # API endpoint for container info
    location /api/containers {
        proxy_pass http://localhost:2375/containers/json;
        proxy_set_header Host \$host;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/containers /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx

    # Create container dashboard
    mkdir -p /var/www/containers
    cat > /var/www/containers/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Container Server - Deployed via Terraform</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; }
        h1 { color: #2c3e50; }
        .status { color: #27ae60; font-weight: bold; }
        .command { background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace; margin: 10px 0; }
        .button { display: inline-block; background: #3498db; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; margin: 5px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Container Server</h1>
        <p class="status">✅ Status: Running (Deployed via Terraform)</p>
        <a href="/portainer/" class="button">🎛️ Portainer Dashboard</a>
        <a href="#commands" class="button">📋 Commands</a>
    </div>

    <div class="grid">
        <div class="container">
            <h3>🚀 Quick Deployment</h3>
            <div class="command">./deploy-container.sh my-nginx nginx:latest 80</div>
            <div class="command">./deploy-container.sh my-app node:18 3000</div>
            <div class="command">./deploy-project.sh ./my-project</div>
        </div>

        <div class="container">
            <h3>🎛️ Management</h3>
            <div class="command">./container-manager.sh running</div>
            <div class="command">./container-manager.sh stats</div>
            <div class="command">./container-manager.sh cleanup</div>
        </div>

        <div class="container">
            <h3>📦 Example Containers</h3>
            <div class="command"># Web servers<br>
nginx:latest, apache:latest<br>
# Databases<br>
postgres:15, mysql:8, redis:7<br>
# Applications<br>
node:18, python:3.11, php:8.2</div>
        </div>

        <div class="container">
            <h3>🔧 Docker Compose</h3>
            <div class="command">cd containers/templates<br>
docker-compose up -d<br>
docker-compose ps<br>
docker-compose logs</div>
        </div>
    </div>

    <div class="container" id="commands">
        <h3>📋 Available Commands</h3>
        <p><strong>Deploy single container:</strong></p>
        <div class="command">./deploy-container.sh &lt;name&gt; &lt;image&gt; [port] [env-file]</div>

        <p><strong>Deploy project with Docker Compose:</strong></p>
        <div class="command">./deploy-project.sh &lt;project-directory&gt;</div>

        <p><strong>Manage containers:</strong></p>
        <div class="command">./container-manager.sh [list|running|stats|logs|stop|start|restart|remove|cleanup|update]</div>

        <p><strong>Access Portainer:</strong></p>
        <div class="command">http://$(hostname -I | awk '{print $1}')/portainer/</div>
    </div>
</body>
</html>
HTML

    # Set ownership
    chown -R docker-user:docker-user /home/docker-user
    chown -R www-data:www-data /var/www/containers

    echo "✅ Container server setup complete via Terraform!"
    echo "🐳 Docker version: $(docker --version)"
    echo "🔧 Docker Compose version: $(docker-compose --version)"
    echo "🎛️ Portainer: http://$(hostname -I | awk '{print $1}'):9000"
    echo "📋 Dashboard: http://$(hostname -I | awk '{print $1}')"
    echo "🔑 SSH as docker-user: ssh docker-user@$(hostname -I | awk '{print $1}')"

    # Log setup completion
    echo "$(date): Container server setup completed via Terraform" >> /var/log/terraform-setup.log
  EOT
}

# VPS instance for container server
resource "hostinger_vps" "container_server" {
  plan                    = var.container_vps_plan
  data_center_id         = var.data_center_id
  template_id            = var.template_id
  hostname               = var.container_server_hostname
  ssh_key_ids            = [hostinger_vps_ssh_key.container_server_key.id]
  post_install_script_id = hostinger_vps_post_install_script.container_server_setup.id

  lifecycle {
    create_before_destroy = true
  }
}

# Output important information
output "container_server_ip" {
  description = "Public IP address of the container server"
  value       = hostinger_vps.container_server.ipv4_address
}

output "container_server_id" {
  description = "ID of the container server VPS"
  value       = hostinger_vps.container_server.id
}

output "portainer_url" {
  description = "Portainer management interface URL"
  value       = "http://${hostinger_vps.container_server.ipv4_address}:9000"
}

output "container_dashboard_url" {
  description = "Container dashboard URL"
  value       = "http://${hostinger_vps.container_server.ipv4_address}"
}

output "container_ssh_command" {
  description = "SSH command to connect as docker user"
  value       = "ssh docker-user@${hostinger_vps.container_server.ipv4_address}"
}

output "example_deployment_commands" {
  description = "Example container deployment commands"
  value = [
    "./deploy-container.sh my-nginx nginx:latest 80",
    "./deploy-container.sh my-app node:18 3000",
    "./deploy-project.sh ./my-project",
    "./container-manager.sh running"
  ]
}
