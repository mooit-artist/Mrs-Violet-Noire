#!/usr/bin/env python3
"""
Hostinger API Python SDK Integration - CORRECTED VERSION
Enhanced Git server automation with proper Python SDK imports
"""

import os
import sys
import json
import base64
from pathlib import Path
from typing import Optional, Dict, List
from dotenv import load_dotenv

# Load Hostinger Python SDK with correct imports
import hostinger_api
from hostinger_api import ApiClient, Configuration
from hostinger_api.exceptions import ApiException

class HostingerManager:
    """Comprehensive Hostinger API management using official Python SDK"""

    def __init__(self, token: Optional[str] = None):
        """Initialize with API token from environment or parameter"""
        if not token:
            # Load from config/secrets.env
            secrets_path = Path("config/secrets.env")
            if secrets_path.exists():
                load_dotenv(secrets_path)
                token = os.getenv("HOSTINGER_API_TOKEN")

        if not token:
            raise ValueError("❌ HOSTINGER_API_TOKEN not found. Check config/secrets.env")

        # Configure SDK with proper imports
        self.configuration = Configuration(access_token=token)
        self.client = ApiClient(self.configuration)

        # Initialize API instances
        self.vps_api = hostinger_api.VPSVirtualMachineApi(self.client)
        self.vps_scripts_api = hostinger_api.VPSPostInstallScriptsApi(self.client)
        self.vps_keys_api = hostinger_api.VPSPublicKeysApi(self.client)
        self.vps_templates_api = hostinger_api.VPSOSTemplatesApi(self.client)
        self.vps_datacenters_api = hostinger_api.VPSDataCentersApi(self.client)
        self.dns_api = hostinger_api.DNSZoneApi(self.client)
        self.domains_api = hostinger_api.DomainsPortfolioApi(self.client)
        self.billing_api = hostinger_api.BillingCatalogApi(self.client)

        print("✅ Hostinger Python SDK initialized")

    def test_connection(self) -> bool:
        """Test API connection"""
        try:
            vps_list = self.vps_api.get_virtual_machine_list_v1()
            print(f"✅ API connection successful. Found {len(vps_list)} VPS instances")
            return True
        except ApiException as e:
            print(f"❌ API connection failed: {e}")
            return False

    def list_vps_instances(self) -> List[Dict]:
        """List all VPS instances"""
        try:
            response = self.vps_api.get_virtual_machine_list_v1()
            instances = []
            for vps in response:
                instances.append({
                    'id': vps.id,
                    'name': vps.name,
                    'status': vps.status,
                    'ip': vps.ipv4.address if vps.ipv4 else 'N/A',
                    'location': vps.location,
                    'template': vps.template.name if vps.template else 'N/A'
                })
            return instances
        except ApiException as e:
            print(f"❌ Error listing VPS: {e}")
            return []

    def list_domains(self) -> List[Dict]:
        """List all domains"""
        try:
            response = self.domains_api.get_domain_list_v1()
            domains = []
            for domain in response:
                domains.append({
                    'name': domain.domain_name,
                    'status': domain.status,
                    'created': domain.created_at,
                    'expires': domain.expires_at
                })
            return domains
        except ApiException as e:
            print(f"❌ Error listing domains: {e}")
            return []

    def get_available_templates(self) -> List[Dict]:
        """Get available OS templates"""
        try:
            response = self.vps_templates_api.get_template_list_v1()
            templates = []
            for template in response:
                templates.append({
                    'id': template.id,
                    'name': template.name,
                    'os': template.os_type,
                    'version': template.version
                })
            return templates
        except ApiException as e:
            print(f"❌ Error getting templates: {e}")
            return []

    def get_data_centers(self) -> List[Dict]:
        """Get available data centers"""
        try:
            response = self.vps_datacenters_api.get_data_centers_list_v1()
            centers = []
            for dc in response:
                centers.append({
                    'id': dc.id,
                    'name': dc.name,
                    'location': dc.location,
                    'country': dc.country
                })
            return centers
        except ApiException as e:
            print(f"❌ Error getting data centers: {e}")
            return []

    def create_git_setup_script(self) -> Optional[str]:
        """Create a post-install script for Git server setup"""
        git_script = """#!/bin/bash
# Automated Git Server Setup Script
# Created by Hostinger API Python SDK

echo "🚀 Starting Git server setup..."

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y git nginx fail2ban ufw curl htop tree

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

# Create helper scripts
cat > /home/git/create-repo.sh <<'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <repository-name>"
    exit 1
fi

REPO_NAME="$1"
REPO_PATH="/srv/git/${REPO_NAME}.git"

if [ -d "$REPO_PATH" ]; then
    echo "❌ Repository $REPO_NAME already exists"
    exit 1
fi

git init --bare "$REPO_PATH"
chown -R git:git "$REPO_PATH"
echo "✅ Repository $REPO_NAME created at $REPO_PATH"
echo "Clone with: git clone git@your-server-ip:$REPO_NAME.git"
SCRIPT

chmod +x /home/git/create-repo.sh
chown git:git /home/git/create-repo.sh

echo "✅ Git server setup complete!"
echo "📋 Next steps:"
echo "1. Add your SSH public key to /home/git/.ssh/authorized_keys"
echo "2. Create repositories with: sudo -u git /home/git/create-repo.sh <repo-name>"
echo "3. Clone with: git clone git@your-server-ip:<repo-name>.git"
"""

        try:
            script_request = hostinger_api.VPSV1PostInstallScriptStoreRequest(
                name="Git Server Setup",
                content=base64.b64encode(git_script.encode()).decode()
            )

            response = self.vps_scripts_api.create_post_install_script_v1(
                vpsv1_post_install_script_store_request=script_request
            )

            print(f"✅ Git setup script created with ID: {response.id}")
            return response.id

        except ApiException as e:
            print(f"❌ Error creating script: {e}")
            return None

    def setup_dns_for_git(self, domain: str, ip_address: str) -> bool:
        """Setup DNS A record for git subdomain"""
        try:
            # Create A record for git.domain.com
            dns_update = hostinger_api.DNSV1ZoneUpdateRequest(
                zone=[
                    hostinger_api.DNSV1ZoneUpdateRequestZoneInner(
                        records=[
                            hostinger_api.DNSV1ZoneUpdateRequestZoneInnerRecordsInner(
                                type="A",
                                name="git",
                                content=ip_address,
                                ttl=3600
                            )
                        ]
                    )
                ]
            )

            self.dns_api.update_zone_records_v1(
                domain=domain,
                dnsv1_zone_update_request=dns_update
            )

            print(f"✅ DNS record created: git.{domain} → {ip_address}")
            return True

        except ApiException as e:
            print(f"❌ Error setting up DNS: {e}")
            return False

    def create_ssh_key(self, name: str, public_key: str) -> Optional[str]:
        """Add SSH public key for VPS access"""
        try:
            key_request = hostinger_api.VPSV1PublicKeyStoreRequest(
                name=name,
                public_key=public_key
            )

            response = self.vps_keys_api.create_new_public_key_v1(
                vpsv1_public_key_store_request=key_request
            )

            print(f"✅ SSH key '{name}' created with ID: {response.id}")
            return response.id

        except ApiException as e:
            print(f"❌ Error creating SSH key: {e}")
            return None

def run_command(action: str, **kwargs):
    """Run specific command with error handling"""
    try:
        manager = HostingerManager()

        if action == "test":
            return manager.test_connection()

        elif action == "list-vps":
            instances = manager.list_vps_instances()
            print(f"\n📋 VPS Instances ({len(instances)}):")
            for vps in instances:
                print(f"  • {vps['name']} ({vps['id']}) - {vps['status']} - {vps['ip']}")
            return instances

        elif action == "list-domains":
            domains = manager.list_domains()
            print(f"\n🌐 Domains ({len(domains)}):")
            for domain in domains:
                print(f"  • {domain['name']} - {domain['status']}")
            return domains

        elif action == "list-templates":
            templates = manager.get_available_templates()
            print(f"\n💿 OS Templates ({len(templates)}):")
            for template in templates:
                print(f"  • {template['name']} ({template['id']}) - {template['os']}")
            return templates

        elif action == "list-datacenters":
            centers = manager.get_data_centers()
            print(f"\n🏢 Data Centers ({len(centers)}):")
            for dc in centers:
                print(f"  • {dc['name']} - {dc['location']}, {dc['country']}")
            return centers

        elif action == "create-git-script":
            script_id = manager.create_git_setup_script()
            if script_id:
                print(f"✅ Use script ID {script_id} when creating VPS")
            return script_id

        elif action == "setup-dns":
            domain = kwargs.get('domain')
            ip = kwargs.get('ip')
            if not domain or not ip:
                print("❌ domain and ip required for DNS setup")
                return False
            return manager.setup_dns_for_git(domain, ip)

    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def main():
    """Main CLI interface"""
    import argparse

    parser = argparse.ArgumentParser(description="Hostinger API Python SDK Manager")
    parser.add_argument("action", choices=[
        "test", "list-vps", "list-domains", "list-templates",
        "list-datacenters", "create-git-script", "setup-dns"
    ])
    parser.add_argument("--domain", help="Domain name for DNS setup")
    parser.add_argument("--ip", help="IP address for DNS setup")

    args = parser.parse_args()

    run_command(args.action, domain=args.domain, ip=args.ip)

if __name__ == "__main__":
    main()
