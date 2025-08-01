# Hostinger Terraform Provider Integration Guide

## 🏗️ **Infrastructure as Code with Terraform**

The [Hostinger Terraform provider](https://github.com/hostinger/terraform-provider-hostinger) enables you to manage your entire infrastructure as code, including VPS instances, SSH keys, and post-install scripts.

### ✅ **What's Now Available**

**Complete Terraform Setup**:
- ✅ **Terraform Configuration** - Ready-to-deploy Git server infrastructure
- ✅ **Automated Deployment** - One-command Git server setup
- ✅ **Infrastructure Management** - Version-controlled infrastructure
- ✅ **Post-Install Automation** - Comprehensive Git server configuration
- ✅ **SSH Key Management** - Automated secure access setup

### 🚀 **Quick Start**

```bash
# 1. Initialize Terraform
./terraform/deploy.sh init

# 2. Plan your infrastructure
./terraform/deploy.sh plan

# 3. Deploy Git server
./terraform/deploy.sh apply

# 4. SSH to your new server
./terraform/deploy.sh ssh
```

### 📁 **File Structure**

```
terraform/
├── main.tf                    # Provider and variable configuration
├── git-server.tf             # Git server infrastructure definition
├── terraform.tfvars.example  # Configuration template
├── deploy.sh                 # Automation script
└── terraform.tfvars          # Your actual configuration (auto-created)
```

### 🔧 **Infrastructure Components**

**1. VPS Instance**:
- Ubuntu 22.04 LTS server
- Configurable plan (Basic/Premium/Business)
- Multiple data center locations
- Custom hostname support

**2. SSH Key Management**:
- Automated SSH key upload
- Secure access configuration
- Key reuse across instances

**3. Post-Install Automation**:
- Complete Git server setup
- Nginx web interface
- Firewall configuration
- Repository management scripts
- Webhook handlers for deployment

**4. DNS Integration** (planned):
- Automatic DNS record creation
- Subdomain management (git.yourdomain.com)

### 🎯 **Deployment Workflow**

**Step 1: Configuration**
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

**Step 2: Deploy Infrastructure**
```bash
./deploy.sh init    # Initialize Terraform
./deploy.sh plan    # Review changes
./deploy.sh apply   # Deploy infrastructure
```

**Step 3: Use Your Git Server**
```bash
# Get server details
./deploy.sh status

# Connect to server
./deploy.sh ssh

# Create repositories
sudo -u git /home/git/create-repo.sh my-project

# Clone repositories
git clone git@SERVER_IP:my-project.git
```

### 💡 **Key Features**

**Infrastructure as Code**:
- Version-controlled infrastructure
- Reproducible deployments
- Easy scaling and modification
- Disaster recovery capabilities

**Automated Git Server**:
- Complete Git hosting solution
- Web interface for repository browsing
- Automated backup capabilities
- Webhook support for CI/CD

**Security Best Practices**:
- SSH key authentication
- Firewall configuration
- Secure user management
- Encrypted communications

### 🔒 **Security Integration**

The Terraform setup integrates with your existing security configuration:
- **API Token**: Loaded from `config/secrets.env`
- **SSH Keys**: Auto-detected from `~/.ssh/id_rsa.pub`
- **Secure Variables**: All sensitive data properly protected

### 📊 **Available Resources**

Check what's available for your infrastructure:

```bash
./deploy.sh resources  # Show available VPS plans, templates, data centers
```

**VPS Plans**:
- Basic: 1 vCPU, 1GB RAM, 20GB SSD
- Premium: 2 vCPU, 4GB RAM, 80GB SSD
- Business: 4 vCPU, 8GB RAM, 160GB SSD

**Data Centers**:
- Netherlands, US West Coast, Singapore, Brazil

**OS Templates**:
- Ubuntu 22.04/20.04 LTS, Debian 11, CentOS 7, AlmaLinux 8

### 🎉 **Complete Infrastructure Stack**

You now have four complementary approaches to Hostinger management:

1. **Shell Scripts** (`scripts/hostinger-api.sh`) - Quick tasks
2. **Python SDK** (`scripts/hostinger_simple.py`) - Automation
3. **Terraform** (`terraform/`) - Infrastructure as Code
4. **Direct API** - Maximum flexibility

**Choose the right tool for each task and combine them for maximum efficiency!** 🚀

### 🔄 **Next Steps**

1. **Deploy Your Git Server**: Use `./terraform/deploy.sh apply`
2. **Configure DNS**: Point `git.yourdomain.com` to your server
3. **Set Up Repositories**: Create your project repositories
4. **Automate Deployments**: Use webhooks for CI/CD integration

**Your complete Git hosting infrastructure is now ready to deploy!** ⚡
