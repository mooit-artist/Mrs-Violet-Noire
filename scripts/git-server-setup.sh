#!/bin/bash
# Git Server Setup via Hostinger API
# This script automates VPS creation and Git server configuration

source scripts/hostinger-api.sh

setup_git_server() {
    echo "🚀 Setting up Git server infrastructure..."

    # 1. Get available OS templates
    echo "📋 Available OS templates:"
    hostinger_api "/vps/v1/templates" | jq '.data[] | select(.name | contains("Ubuntu")) | {id, name}'

    # 2. Get data centers
    echo "🏢 Available data centers:"
    hostinger_api "/vps/v1/data-centers"

    # 3. Create post-install script for Git setup
    local git_setup_script=$(cat << 'EOF'
#!/bin/bash
# Automated Git server setup
apt update && apt upgrade -y
apt install -y git nginx fail2ban ufw

# Create git user
adduser --system --group --shell /bin/bash --home /home/git git
mkdir -p /home/git/.ssh
touch /home/git/.ssh/authorized_keys
chmod 700 /home/git/.ssh
chmod 600 /home/git/.ssh/authorized_keys
chown -R git:git /home/git/.ssh

# Setup firewall
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# Create repositories directory
mkdir -p /srv/git
chown -R git:git /srv/git

echo "✅ Git server setup complete!"
EOF
)

    echo "📝 Creating post-install script..."
    local script_response=$(echo "$git_setup_script" | base64 | tr -d '\n')

    curl -s -X POST \
        -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Git Server Setup\",
            \"script\": \"$script_response\"
        }" \
        "$HOSTINGER_API_BASE/vps/v1/post-install-scripts"
}

setup_git_dns() {
    local domain="$1"
    local vps_ip="$2"

    if [ -z "$domain" ] || [ -z "$vps_ip" ]; then
        echo "❌ Usage: setup_git_dns <domain> <vps_ip>"
        return 1
    fi

    echo "🌐 Setting up DNS for git.$domain → $vps_ip"

    # Add A record for git subdomain
    curl -s -X PUT \
        -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"records\": [
                {
                    \"type\": \"A\",
                    \"name\": \"git\",
                    \"content\": \"$vps_ip\",
                    \"ttl\": 3600
                }
            ]
        }" \
        "$HOSTINGER_API_BASE/dns/v1/zones/$domain"
}

create_git_repo() {
    local vps_id="$1"
    local repo_name="$2"

    if [ -z "$vps_id" ] || [ -z "$repo_name" ]; then
        echo "❌ Usage: create_git_repo <vps_id> <repo_name>"
        return 1
    fi

    echo "📁 Creating Git repository: $repo_name"

    # This would require SSH access to the VPS
    # The API doesn't directly support running commands on VPS
    echo "ℹ️ To create repositories, SSH to your VPS and run:"
    echo "ssh git@your-server-ip"
    echo "cd /srv/git"
    echo "git init --bare $repo_name.git"
    echo "chown -R git:git $repo_name.git"
}

# Show help
show_git_help() {
    echo "Git Server Setup Commands:"
    echo "  setup_git_server                    - Create VPS with Git server"
    echo "  setup_git_dns <domain> <ip>         - Configure DNS for Git"
    echo "  create_git_repo <vps_id> <name>     - Instructions for repo creation"
}
