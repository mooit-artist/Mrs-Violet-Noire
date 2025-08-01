#!/bin/bash
# Hostinger API Helper Script
# Source this file to load API credentials: source scripts/hostinger-api.sh

# Load environment variables from config/secrets.env
if [ -f "config/secrets.env" ]; then
    export $(cat config/secrets.env | grep -v '^#' | xargs)
    echo "✅ Hostinger API credentials loaded"
else
    echo "❌ Error: config/secrets.env not found"
    echo "   Copy config/secrets.env.template to config/secrets.env and add your API token"
    exit 1
fi

# Hostinger API base URL
export HOSTINGER_API_BASE="https://api.hostinger.com/v1"

# Helper function to make API calls
hostinger_api() {
    local endpoint="$1"
    local method="${2:-GET}"

    if [ -z "$HOSTINGER_API_TOKEN" ]; then
        echo "❌ Error: HOSTINGER_API_TOKEN not set"
        return 1
    fi

    curl -s -X "$method" \
        -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$HOSTINGER_API_BASE$endpoint"
}

# Test API connection
test_hostinger_api() {
    echo "🔗 Testing Hostinger API connection..."
    response=$(hostinger_api "/vps")

    if echo "$response" | grep -q '"message"'; then
        echo "❌ API Error: $response"
    else
        echo "✅ API connection successful"
        echo "VPS instances: $response"
    fi
}

# Quick API functions for common operations
check_domains() {
    echo "🌐 Checking your domains..."
    hostinger_api "/domains/v1/portfolio"
}

check_vps() {
    echo "💻 Checking your VPS instances..."
    hostinger_api "/vps/v1/virtual-machines"
}

check_subscriptions() {
    echo "💳 Checking your subscriptions..."
    hostinger_api "/billing/v1/subscriptions"
}

list_datacenters() {
    echo "🏢 Available data centers..."
    hostinger_api "/vps/v1/data-centers"
}

check_dns_zone() {
    local domain="$1"
    if [ -z "$domain" ]; then
        echo "❌ Usage: check_dns_zone <domain>"
        return 1
    fi
    echo "🔍 Checking DNS zone for $domain..."
    hostinger_api "/dns/v1/zones/$domain"
}

# Show available commands
show_hostinger_help() {
    echo "Hostinger API Helper Commands:"
    echo "  test_hostinger_api    - Test API connection"
    echo "  hostinger_api <endpoint> [method] - Make API call"
    echo ""
    echo "Quick Commands:"
    echo "  check_domains         - List your domains"
    echo "  check_vps             - List your VPS instances"
    echo "  check_subscriptions   - List your subscriptions"
    echo "  list_datacenters      - Show available data centers"
    echo "  check_dns_zone <domain> - Check DNS zone for domain"
    echo ""
    echo "Example usage:"
    echo "  hostinger_api '/vps/v1/virtual-machines'     # GET VPS list"
    echo "  hostinger_api '/billing/v1/catalog'          # GET service catalog"
    echo "  check_domains                                # Quick domain check"
}
