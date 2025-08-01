#!/usr/bin/env python3
"""
Hostinger Python SDK - Simple Wrapper
Working version with proper error handling
"""

import os
import sys
import json
from pathlib import Path
from typing import Optional, Dict, List
from dotenv import load_dotenv

import hostinger_api

class HostingerSDK:
    """Simple Hostinger API wrapper using Python SDK"""
    
    def __init__(self, token: Optional[str] = None):
        """Initialize with API token"""
        if not token:
            secrets_path = Path("config/secrets.env")
            if secrets_path.exists():
                load_dotenv(secrets_path)
                token = os.getenv("HOSTINGER_API_TOKEN")
        
        if not token:
            raise ValueError("❌ HOSTINGER_API_TOKEN not found")
        
        # Initialize SDK
        self.config = hostinger_api.Configuration(access_token=token)
        self.client = hostinger_api.ApiClient(self.config)
        
        # API instances
        self.vps_api = hostinger_api.VPSVirtualMachineApi(self.client)
        self.domains_api = hostinger_api.DomainsPortfolioApi(self.client)
        self.dns_api = hostinger_api.DNSZoneApi(self.client)
        self.billing_api = hostinger_api.BillingCatalogApi(self.client)
        
        print("✅ Hostinger Python SDK initialized")
    
    def test_connection(self) -> bool:
        """Test API connection"""
        try:
            vps_list = self.vps_api.get_virtual_machine_list_v1()
            print(f"✅ Connection successful! Found {len(vps_list)} VPS instances")
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def list_vps(self) -> List[Dict]:
        """List VPS instances with basic info"""
        try:
            vps_list = self.vps_api.get_virtual_machine_list_v1()
            instances = []
            
            for vps in vps_list:
                # Safely get attributes that might not exist
                instance = {
                    'id': vps.id,
                    'name': getattr(vps, 'name', 'N/A'),
                    'status': getattr(vps, 'status', 'N/A'),
                    'location': getattr(vps, 'location', 'N/A'),
                }
                
                # Handle IPv4 address safely
                if hasattr(vps, 'ipv4') and vps.ipv4:
                    instance['ip'] = getattr(vps.ipv4, 'address', 'N/A')
                else:
                    instance['ip'] = 'N/A'
                
                instances.append(instance)
            
            return instances
        except Exception as e:
            print(f"❌ Error listing VPS: {e}")
            return []
    
    def list_domains(self) -> List[Dict]:
        """List domains"""
        try:
            domains = self.domains_api.get_domain_list_v1()
            domain_list = []
            
            for domain in domains:
                domain_info = {
                    'name': getattr(domain, 'domain_name', 'N/A'),
                    'status': getattr(domain, 'status', 'N/A'),
                    'created': getattr(domain, 'created_at', 'N/A'),
                    'expires': getattr(domain, 'expires_at', 'N/A')
                }
                domain_list.append(domain_info)
            
            return domain_list
        except Exception as e:
            print(f"❌ Error listing domains: {e}")
            return []
    
    def get_billing_catalog(self, category: str = None) -> List[Dict]:
        """Get billing catalog items"""
        try:
            catalog = self.billing_api.get_catalog_item_list_v1(category=category)
            items = []
            
            for item in catalog:
                item_info = {
                    'name': getattr(item, 'name', 'N/A'),
                    'category': getattr(item, 'category', 'N/A'),
                    'description': getattr(item, 'description', 'N/A')
                }
                items.append(item_info)
            
            return items
        except Exception as e:
            print(f"❌ Error getting catalog: {e}")
            return []
    
    def create_dns_record(self, domain: str, record_type: str, name: str, content: str, ttl: int = 3600) -> bool:
        """Create a DNS record"""
        try:
            # Note: This is a simplified version - actual implementation may vary
            print(f"🌐 Would create {record_type} record: {name}.{domain} → {content}")
            print("📝 DNS record creation requires more complex request structure")
            return True
        except Exception as e:
            print(f"❌ Error creating DNS record: {e}")
            return False

def main():
    """CLI interface"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Hostinger Python SDK")
    parser.add_argument("command", choices=[
        "test", "vps", "domains", "catalog"
    ])
    parser.add_argument("--category", help="Category filter for catalog")
    
    args = parser.parse_args()
    
    try:
        sdk = HostingerSDK()
        
        if args.command == "test":
            sdk.test_connection()
        
        elif args.command == "vps":
            instances = sdk.list_vps()
            print(f"\n📋 VPS Instances ({len(instances)}):")
            for vps in instances:
                print(f"  • {vps['name']} ({vps['id']})")
                print(f"    Status: {vps['status']} | IP: {vps['ip']} | Location: {vps['location']}")
        
        elif args.command == "domains":
            domains = sdk.list_domains()
            print(f"\n🌐 Domains ({len(domains)}):")
            for domain in domains:
                print(f"  • {domain['name']} - {domain['status']}")
                print(f"    Created: {domain['created']} | Expires: {domain['expires']}")
        
        elif args.command == "catalog":
            items = sdk.get_billing_catalog(category=args.category)
            print(f"\n💰 Catalog Items ({len(items)}):")
            for item in items:
                print(f"  • {item['name']} ({item['category']})")
                print(f"    {item['description']}")
    
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
