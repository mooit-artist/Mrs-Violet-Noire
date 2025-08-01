# Container Deployment Guide for Hostinger VPS

## 🐳 **Deploy Containers to VPS with One Command**

Your Terraform infrastructure now includes **complete container deployment capabilities** with Docker, Docker Compose, and Portainer management interface.

### ✅ **What's Now Available**

**Complete Container Platform**:
- ✅ **Docker Engine** - Latest Docker installation
- ✅ **Docker Compose** - Multi-container orchestration
- ✅ **Portainer** - Web-based container management
- ✅ **Nginx Proxy** - Container web interface
- ✅ **Automated Scripts** - One-command deployments
- ✅ **Security** - Firewall and user management

### 🚀 **Quick Start**

```bash
# 1. Deploy container server infrastructure
./terraform/deploy.sh init
./terraform/deploy.sh plan
./terraform/deploy.sh apply

# 2. Deploy your first container
./terraform/deploy.sh deploy-container my-nginx nginx:latest 80

# 3. Access your containers
# Dashboard: http://SERVER_IP
# Portainer: http://SERVER_IP:9000
# Your app: http://SERVER_IP:80
```

### 📁 **Enhanced File Structure**

```
terraform/
├── main.tf                    # Provider and variables
├── git-server.tf             # Git server infrastructure
├── container-server.tf       # 🆕 Container server infrastructure
├── terraform.tfvars.example  # Configuration template (updated)
├── deploy.sh                 # 🆕 Enhanced automation script
└── terraform.tfvars          # Your configuration
```

### 🐳 **Container Server Features**

**1. Docker Environment**:
- Latest Docker Engine with automatic updates
- Docker Compose for multi-container applications
- Dedicated `docker-user` with proper permissions
- Automated container lifecycle management

**2. Portainer Management**:
- Web-based container dashboard at `:9000`
- Visual container deployment and monitoring
- Image management and registry integration
- Container logs and statistics

**3. Deployment Automation**:
- One-command container deployment
- Docker Compose project deployment
- Container lifecycle management scripts
- Automated cleanup and maintenance

**4. Security & Networking**:
- Firewall configured for container ports
- SSH access with key authentication
- Nginx reverse proxy capabilities
- Network isolation and management

### 🎯 **Deployment Examples**

**Deploy Single Containers**:
```bash
# Web servers
./terraform/deploy.sh deploy-container my-nginx nginx:latest 80
./terraform/deploy.sh deploy-container my-apache httpd:latest 8080

# Databases
./terraform/deploy.sh deploy-container my-postgres postgres:15 5432
./terraform/deploy.sh deploy-container my-redis redis:7-alpine 6379

# Applications
./terraform/deploy.sh deploy-container my-node-app node:18 3000
./terraform/deploy.sh deploy-container my-python-app python:3.11 5000
```

**Deploy Multi-Container Projects**:
```bash
# SSH to container server
./terraform/deploy.sh ssh-container

# Deploy with Docker Compose
cd containers/templates
docker-compose up -d

# Or deploy custom project
./deploy-project.sh /path/to/your/project
```

### 🔧 **Container Management**

**SSH to Container Server**:
```bash
./terraform/deploy.sh ssh-container
```

**Management Commands** (on container server):
```bash
# List containers
./container-manager.sh running

# Container stats
./container-manager.sh stats

# View logs
./container-manager.sh logs my-nginx

# Stop/start containers
./container-manager.sh stop my-nginx
./container-manager.sh start my-nginx

# Cleanup unused resources
./container-manager.sh cleanup

# Update all images
./container-manager.sh update
```

### 📊 **Available Container Types**

**Web Servers**:
- `nginx:latest` - High-performance web server
- `apache:latest` - Traditional web server
- `caddy:latest` - Modern web server with auto-HTTPS

**Databases**:
- `postgres:15` - PostgreSQL database
- `mysql:8` - MySQL database
- `redis:7-alpine` - Redis cache/database
- `mongodb:6` - MongoDB NoSQL database

**Application Runtimes**:
- `node:18` - Node.js applications
- `python:3.11` - Python applications
- `php:8.2-fpm` - PHP applications
- `openjdk:17` - Java applications

**Development Tools**:
- `jenkins/jenkins` - CI/CD pipeline
- `gitlab/gitlab-ce` - Git repository management
- `nextcloud` - File sharing platform
- `wordpress` - Content management

### 🎛️ **Portainer Dashboard**

Access the Portainer web interface for visual container management:

1. **URL**: `http://YOUR_SERVER_IP:9000`
2. **First Setup**: Create admin account on first visit
3. **Features**:
   - Visual container deployment
   - Image and volume management
   - Container logs and statistics
   - Registry management
   - Stack deployment

### 🔄 **Docker Compose Templates**

The container server includes ready-to-use Docker Compose templates:

**Web Application Stack**:
```yaml
version: '3.8'
services:
  webapp:
    image: nginx:latest
    ports: ["80:80"]
    volumes: ["./html:/usr/share/nginx/html"]

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes: ["postgres_data:/var/lib/postgresql/data"]

  cache:
    image: redis:7-alpine
    ports: ["6379:6379"]
```

**Deploy Templates**:
```bash
# SSH to container server
./terraform/deploy.sh ssh-container

# Use provided templates
cd containers/templates
docker-compose up -d
```

### 🌐 **Network Access**

**Container Dashboard**: `http://SERVER_IP`
- Overview of all running containers
- Quick deployment commands
- Management interface links

**Portainer Interface**: `http://SERVER_IP:9000`
- Complete container management
- Visual deployment tools
- Monitoring and logs

**Direct Container Access**: `http://SERVER_IP:PORT`
- Access deployed applications directly
- Ports configured automatically during deployment

### 🔒 **Security Best Practices**

**Firewall Configuration**:
- SSH (22), HTTP (80), HTTPS (443) open
- Portainer (9000) for management
- Common development ports (3000, 5000, 8000, 8080)
- Custom ports opened automatically during deployment

**User Management**:
- Dedicated `docker-user` for container operations
- SSH key authentication required
- Proper Docker group permissions
- Isolated container environment

**Container Security**:
- Containers run with limited privileges
- Network isolation between containers
- Regular security updates for base images
- Volume and data protection

### 💡 **Advanced Use Cases**

**1. Microservices Architecture**:
```bash
# Deploy API backend
./deploy-container.sh api-backend node:18 3000

# Deploy database
./deploy-container.sh api-database postgres:15 5432

# Deploy Redis cache
./deploy-container.sh api-cache redis:7-alpine 6379

# Deploy frontend
./deploy-container.sh frontend nginx:latest 80
```

**2. Development Environment**:
```bash
# Code editor in browser
./deploy-container.sh code-server codercom/code-server:latest 8080

# Database for development
./deploy-container.sh dev-db postgres:15 5432

# File sharing
./deploy-container.sh files nextcloud:latest 8000
```

**3. CI/CD Pipeline**:
```bash
# Jenkins for automation
./deploy-container.sh jenkins jenkins/jenkins:latest 8080

# Git server (if not using separate git server)
./deploy-container.sh gitea gitea/gitea:latest 3000

# Registry for container images
./deploy-container.sh registry registry:2 5000
```

### 📈 **Monitoring & Maintenance**

**Resource Monitoring**:
```bash
# Check resource usage
./container-manager.sh stats

# View system resources
htop
df -h
```

**Log Management**:
```bash
# Container logs
./container-manager.sh logs CONTAINER_NAME

# System logs
journalctl -f
tail -f /var/log/terraform-setup.log
```

**Backup & Recovery**:
```bash
# Backup container data
docker run --rm -v container_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Restore container data
docker run --rm -v container_data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /
```

### 🎉 **Complete Infrastructure Stack**

You now have **FIVE** complementary approaches to infrastructure management:

1. **Shell Scripts** (`scripts/hostinger-api.sh`) - Quick API tasks
2. **Python SDK** (`scripts/hostinger_simple.py`) - Automation scripts
3. **Terraform Git Server** (`terraform/git-server.tf`) - Git infrastructure
4. **🆕 Terraform Container Server** (`terraform/container-server.tf`) - Container infrastructure
5. **Direct API** - Maximum flexibility

### 🔄 **Next Steps**

1. **Deploy Container Infrastructure**:
   ```bash
   ./terraform/deploy.sh apply
   ```

2. **Configure DNS** (optional):
   ```bash
   # Point containers.yourdomain.com to your server
   # Configure in your DNS provider
   ```

3. **Deploy Your Applications**:
   ```bash
   ./terraform/deploy.sh deploy-container my-app your-image:latest 3000
   ```

4. **Set Up Monitoring**: Use Portainer dashboard for ongoing management

**Your complete container hosting platform is ready to deploy! 🐳⚡**

### 🆘 **Troubleshooting**

**Common Issues**:

1. **Container won't start**: Check logs with `./container-manager.sh logs CONTAINER_NAME`
2. **Port conflicts**: Use different ports or stop conflicting containers
3. **Permission issues**: Ensure you're using `docker-user` account
4. **Network issues**: Check firewall rules and container networking

**Get Help**:
```bash
# Check container status
./container-manager.sh running

# View system status
./terraform/deploy.sh status

# SSH for direct troubleshooting
./terraform/deploy.sh ssh-container
```

**Your enterprise-grade container platform is ready for production workloads! 🚀**
