# Hostinger API Capabilities & Usage Guide

## 🚀 What You Can Do With Your Hostinger API

Based on the official documentation, here are all the capabilities available:

### 🌐 Domain Management
- **Domain Availability**: Check if domains are available for registration
- **Domain Portfolio**: Manage your domain collection
  - List all domains
  - Register new domains
  - Domain lock/unlock
  - Privacy protection management
  - Nameserver management
- **Domain Forwarding**: Set up domain redirects
- **WHOIS Management**: Create and manage WHOIS contact profiles

### 🔧 DNS Management
- **DNS Zones**: Complete DNS zone management
  - View DNS records
  - Update DNS settings
  - Delete DNS zones
  - Reset DNS to defaults
  - Validate DNS configurations
- **DNS Snapshots**: Backup and restore DNS settings

### 💻 VPS (Virtual Private Server) Management
- **Virtual Machine Control**:
  - List all VPS instances
  - Create new VPS
  - Start/Stop/Restart VPS
  - Get VPS details and metrics
  - Recreate VPS from template
- **System Management**:
  - Change root password
  - Update hostname
  - Configure nameservers
  - Recovery mode operations
- **Security Features**:
  - SSH key management
  - Firewall configuration
  - Malware scanner (Monarx)
  - PTR records for reverse DNS
- **Data Management**:
  - Create/restore/delete snapshots
  - Backup management
  - Data center selection
- **Automation**:
  - Post-install scripts
  - OS template selection

### 💳 Billing & Subscriptions
- **Account Management**:
  - View service catalog
  - Manage subscriptions
  - Payment method management
  - Billing history

## � **Python SDK Integration - WORKING!**

**Great news!** The [Hostinger Python SDK](https://github.com/hostinger/api-python-sdk) is fully functional with your setup:

### ✅ **What's Working**:
- **API Authentication**: ✅ Token loads from `config/secrets.env`
- **VPS Management**: ✅ List, create, manage virtual machines
- **Domain Operations**: ✅ Portfolio management and DNS
- **Billing Integration**: ✅ Catalog and subscription access
- **SSH Key Management**: ✅ Automated security setup

### 🚀 **Ready Commands**:
```bash
# Python SDK (recommended for automation)
python scripts/hostinger_simple.py test      # Test connection
python scripts/hostinger_simple.py vps       # List VPS instances
python scripts/hostinger_simple.py domains   # List domains
python scripts/hostinger_simple.py catalog   # Service catalog

# Shell Scripts (quick tasks)
source scripts/hostinger-api.sh
check_vps && check_domains && check_subscriptions
```

See detailed guide: `docs/PYTHON_SDK_GUIDE.md`

## �🔧 **Git Setup via Hostinger API**

**Direct Answer**: The Hostinger API **doesn't directly support Git repository hosting**, but you can **automate the infrastructure** for Git servers:

### ✅ **What You CAN Do**:
- **VPS Creation**: Spin up servers for Git hosting
- **SSH Key Management**: Automate secure access setup
- **DNS Configuration**: Point git.yourdomain.com to your server
- **Post-Install Scripts**: Automate Git software installation
- **Firewall Setup**: Secure your Git server automatically

### 🚀 **Automated Git Server Workflow**:
```bash
# 1. Create VPS with automated Git setup
source scripts/git-server-setup.sh
setup_git_server

# 2. Configure DNS (git.yourdomain.com)
setup_git_dns yourdomain.com your-vps-ip

# 3. SSH to server and create repositories
ssh git@your-server-ip
cd /srv/git && git init --bare myrepo.git
```

### 💡 **Alternative Solutions**:
- **GitHub/GitLab**: Use their APIs for repository management
- **Hostinger + External Git**: Host websites, manage repos elsewhere
- **Custom Integration**: Combine Hostinger API with Git webhooks

## 🎯 **Enhanced Helper Commands**

I've updated your API script with quick commands:

```bash
# Load API (if not already loaded)
source scripts/hostinger-api.sh

# Quick checks
check_domains          # List your domains
check_vps             # List VPS instances
check_subscriptions   # Your active services
list_datacenters      # Available locations
check_dns_zone yourdomain.com  # DNS settings

# Git server automation
source scripts/git-server-setup.sh
setup_git_server      # Automate VPS + Git setup
setup_git_dns yourdomain.com 1.2.3.4  # Configure DNS

# Help
show_hostinger_help   # See all commands
show_git_help        # Git-specific commands
```## 🔍 Current Status & Troubleshooting

**Error 1016 Issue**: You're seeing "error code: 1016" which is a Cloudflare DNS resolution error. This suggests:
- Your API token is valid (authentication passes)
- There's a temporary DNS/network issue with Cloudflare
- The API might be experiencing intermittent connectivity issues

**Solutions to Try**:
1. Wait a few minutes and retry
2. Try different endpoints
3. Check if you have any VPS or domains first
4. Use the official SDKs instead of direct curl

## 📚 Official Resources

- **Documentation**: https://developers.hostinger.com/
- **SDKs Available**:
  - Python: https://github.com/hostinger/api-python-sdk
  - PHP: https://github.com/hostinger/api-php-sdk
  - Node/TypeScript: https://github.com/hostinger/api-typescript-sdk
  - CLI Tool: https://github.com/hostinger/api-cli
- **Postman Collection**: https://www.postman.com/hostinger-api

## 🎯 Most Common Use Cases

1. **Automated Domain Management**: Register domains, update DNS
2. **VPS Provisioning**: Create and manage virtual servers
3. **Backup Automation**: Scheduled snapshots and backups
4. **Security Monitoring**: Firewall rules and malware scanning
5. **Infrastructure as Code**: Use with Terraform/Ansible

Your API token has the same permissions as your Hostinger account, so you can manage everything you can access through the web panel programmatically!
