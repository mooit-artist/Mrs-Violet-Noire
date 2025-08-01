# Data sources to get available options
data "hostinger_vps_templates" "all" {}
data "hostinger_vps_data_centers" "all" {}
data "hostinger_vps_plans" "all" {}

# SSH Key for VPS access
resource "hostinger_vps_ssh_key" "git_server_key" {
  name = "Git Server SSH Key"
  key  = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
}

# Post-install script for Git server setup
resource "hostinger_vps_post_install_script" "git_server_setup" {
  name    = "Git Server Setup Script"
  content = <<-EOT
    #!/bin/bash
    # Automated Git Server Setup via Terraform

    echo "🚀 Starting Git server setup via Terraform..."

    # Update system
    apt update && apt upgrade -y

    # Install required packages
    apt install -y git nginx fail2ban ufw curl htop tree jq

    # Create git user
    if ! id "git" &>/dev/null; then
        adduser --system --group --shell /bin/bash --home /home/git git
        echo "✅ Git user created"
    fi

    # Setup SSH directory for git user
    mkdir -p /home/git/.ssh
    touch /home/git/.ssh/authorized_keys
    chmod 700 /home/git/.ssh
    chmod 600 /home/git/.ssh/authorized_keys
    chown -R git:git /home/git/.ssh

    # Create repositories directory
    mkdir -p /srv/git
    chown -R git:git /srv/git
    echo "✅ Git repositories directory created"

    # Setup firewall
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 9418  # Git protocol
    ufw --force enable
    echo "✅ Firewall configured"

    # Configure Nginx for Git web interface
    cat > /etc/nginx/sites-available/git <<EOF
server {
    listen 80;
    server_name git.* ${var.git_server_hostname};

    location / {
        return 301 https://github.com/mooit-artist;
    }

    location /health {
        return 200 'Git server is running - Deployed via Terraform';
        add_header Content-Type text/plain;
    }

    location /repos {
        autoindex on;
        alias /srv/git/;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/git /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx

    # Create repository management scripts
    cat > /home/git/create-repo.sh <<'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <repository-name>"
    exit 1
fi

REPO_NAME="$1"
REPO_PATH="/srv/git/$${REPO_NAME}.git"

if [ -d "$REPO_PATH" ]; then
    echo "❌ Repository $REPO_NAME already exists"
    exit 1
fi

git init --bare "$REPO_PATH"
chown -R git:git "$REPO_PATH"
echo "✅ Repository $REPO_NAME created at $REPO_PATH"
echo "Clone with: git clone git@$(hostname -I | awk '{print $1}'):$REPO_NAME.git"
SCRIPT

    chmod +x /home/git/create-repo.sh
    chown git:git /home/git/create-repo.sh

    # Create sample repository
    sudo -u git /home/git/create-repo.sh sample-project

    # Setup webhook handler (optional)
    cat > /home/git/webhook-handler.sh <<'WEBHOOK'
#!/bin/bash
# Simple webhook handler for deployment automation
# Usage: Call this script from Git hooks for automatic deployment

REPO_NAME="$1"
DEPLOY_PATH="/var/www/$REPO_NAME"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <repository-name>"
    exit 1
fi

echo "🚀 Deploying $REPO_NAME..."

# Clone or pull latest changes
if [ ! -d "$DEPLOY_PATH" ]; then
    git clone "/srv/git/$${REPO_NAME}.git" "$DEPLOY_PATH"
else
    cd "$DEPLOY_PATH" && git pull origin main
fi

# Set permissions
chown -R www-data:www-data "$DEPLOY_PATH"
echo "✅ Deployment complete for $REPO_NAME"
WEBHOOK

    chmod +x /home/git/webhook-handler.sh
    chown git:git /home/git/webhook-handler.sh

    # Create status endpoint
    mkdir -p /var/www/html
    cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Git Server - Deployed via Terraform</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .status { color: #27ae60; font-weight: bold; }
        .command { background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Git Server</h1>
        <p class="status">✅ Status: Running (Deployed via Terraform)</p>
        <h3>Available Repositories:</h3>
        <ul>
            <li>sample-project.git</li>
        </ul>
        <h3>Clone Command:</h3>
        <div class="command">git clone git@$(hostname -I | awk '{print $1}'):sample-project.git</div>
        <h3>Create New Repository:</h3>
        <div class="command">sudo -u git /home/git/create-repo.sh &lt;repo-name&gt;</div>
    </div>
</body>
</html>
HTML

    echo "✅ Git server setup complete via Terraform!"
    echo "📋 Server accessible at: http://$(hostname -I | awk '{print $1}')"
    echo "🔑 Add your SSH key to /home/git/.ssh/authorized_keys to access repositories"

    # Log setup completion
    echo "$(date): Git server setup completed via Terraform" >> /var/log/terraform-setup.log
  EOT
}

# VPS instance for Git server
resource "hostinger_vps" "git_server" {
  plan                    = var.vps_plan
  data_center_id         = var.data_center_id
  template_id            = var.template_id
  hostname               = var.git_server_hostname
  ssh_key_ids            = [hostinger_vps_ssh_key.git_server_key.id]
  post_install_script_id = hostinger_vps_post_install_script.git_server_setup.id

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record for git subdomain (requires domain management via API)
# Note: This would need to be implemented with the DNS management API
# For now, this is a placeholder showing the intended configuration

# Output important information
output "git_server_ip" {
  description = "Public IP address of the Git server"
  value       = hostinger_vps.git_server.ipv4_address
}

output "git_server_id" {
  description = "ID of the Git server VPS"
  value       = hostinger_vps.git_server.id
}

output "ssh_key_id" {
  description = "ID of the created SSH key"
  value       = hostinger_vps_ssh_key.git_server_key.id
}

output "post_install_script_id" {
  description = "ID of the post-install script"
  value       = hostinger_vps_post_install_script.git_server_setup.id
}

output "git_clone_command" {
  description = "Example Git clone command"
  value       = "git clone git@${hostinger_vps.git_server.ipv4_address}:sample-project.git"
}

output "server_status_url" {
  description = "URL to check server status"
  value       = "http://${hostinger_vps.git_server.ipv4_address}"
}

# Output available resources for reference
output "available_templates" {
  description = "Available OS templates"
  value       = data.hostinger_vps_templates.all.templates
}

output "available_data_centers" {
  description = "Available data centers"
  value       = data.hostinger_vps_data_centers.all.data_centers
}

output "available_plans" {
  description = "Available VPS plans"
  value       = data.hostinger_vps_plans.all.plans
}
