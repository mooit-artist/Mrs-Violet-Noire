#!/bin/bash
# Simple Website Deployment to Hostinger Shared Hosting
# This script syncs your local files to your Hostinger web hosting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_FILE="$PROJECT_ROOT/config/secrets.env"

# Load environment variables
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
else
    print_error "Secrets file not found: $SECRETS_FILE"
    print_status "Copy config/secrets.env.template to config/secrets.env and add your FTP credentials"
    exit 1
fi

# Check required variables
check_credentials() {
    local missing=0

    if [ -z "$HOSTINGER_FTP_HOST" ]; then
        print_error "HOSTINGER_FTP_HOST not set in secrets.env"
        missing=1
    fi

    if [ -z "$HOSTINGER_FTP_USER" ]; then
        print_error "HOSTINGER_FTP_USER not set in secrets.env"
        missing=1
    fi

    if [ -z "$HOSTINGER_FTP_PASS" ]; then
        print_error "HOSTINGER_FTP_PASS not set in secrets.env"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        print_status "Add these variables to your config/secrets.env:"
        echo "HOSTINGER_FTP_HOST=your-domain.com"
        echo "HOSTINGER_FTP_USER=your-ftp-username"
        echo "HOSTINGER_FTP_PASS=your-ftp-password"
        exit 1
    fi
}

# Deploy via FTP (Hostinger shared hosting standard)
deploy_ftp() {
    print_status "🚀 Deploying website via FTP..."

    # Check if lftp is installed
    if ! command -v lftp &> /dev/null; then
        print_error "lftp not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install lftp
        else
            sudo apt-get install -y lftp
        fi
    fi

    # Files to upload
    local files=(
        "index.html"
        "css/"
        "js/"
        "MrsVioletNoire.png"
    )

    print_status "📁 Files to upload: ${files[*]}"

    # Create FTP batch script
    cat > /tmp/ftp_commands.txt << EOF
set ssl:verify-certificate false
set ftp:ssl-allow false
set ftp:passive-mode on
lcd $PROJECT_ROOT
put index.html
mirror -R css css
mirror -R js js
put MrsVioletNoire.png
quit
EOF

    # Execute FTP upload
    print_status "📤 Uploading files via FTP..."
    lftp -f /tmp/ftp_commands.txt -u "$HOSTINGER_FTP_USER,$HOSTINGER_FTP_PASS" ftp://"$HOSTINGER_FTP_HOST"

    # Clean up
    rm /tmp/ftp_commands.txt

    print_success "✅ Website deployed successfully!"
    print_status "🌐 Your website should now be live at: https://mrsvioletnoire.com"
}

# Deploy via SFTP
deploy_sftp() {
    print_status "🚀 Deploying website via SFTP..."

    # Check if lftp is installed
    if ! command -v lftp &> /dev/null; then
        print_error "lftp not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install lftp
        else
            sudo apt-get install -y lftp
        fi
    fi

    # Files to upload
    local files=(
        "index.html"
        "css/"
        "js/"
        "MrsVioletNoire.png"
    )

    print_status "📁 Files to upload: ${files[*]}"

    # Create SFTP batch script
    cat > /tmp/sftp_commands.txt << EOF
cd public_html
lcd $PROJECT_ROOT
put index.html
mirror -R css css
mirror -R js js
put MrsVioletNoire.png
quit
EOF

    # Execute SFTP upload
    print_status "📤 Uploading files..."
    lftp -f /tmp/sftp_commands.txt -u "$HOSTINGER_FTP_USER,$HOSTINGER_FTP_PASS" sftp://"$HOSTINGER_FTP_HOST"

    # Clean up
    rm /tmp/sftp_commands.txt

    print_success "✅ Website deployed successfully!"
    print_status "🌐 Your website should now be live at: https://mrsvioletnoire.com"
}

# Deploy via FTPS (FTP over SSL/TLS - fallback)
deploy_ftps() {
    print_status "🚀 Deploying website via FTPS (FTP over SSL)..."

    # Check if lftp is installed
    if ! command -v lftp &> /dev/null; then
        print_error "lftp not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install lftp
        else
            sudo apt-get install -y lftp
        fi
    fi

    # Create FTPS batch script with SSL settings
    cat > /tmp/ftps_commands.txt << EOF
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate false
cd public_html
lcd $PROJECT_ROOT
put index.html
mirror -R css css
mirror -R js js
put MrsVioletNoire.png
quit
EOF

    # Execute FTPS upload (FTP over SSL/TLS)
    print_status "📤 Uploading files via FTPS..."
    lftp -f /tmp/ftps_commands.txt -u "$HOSTINGER_FTP_USER,$HOSTINGER_FTP_PASS" ftps://"$HOSTINGER_FTP_HOST"

    # Clean up
    rm /tmp/ftps_commands.txt

    print_success "✅ Website deployed successfully!"
    print_status "🌐 Your website should now be live at: https://mrsvioletnoire.com"
}

# Test website after deployment
test_deployment() {
    print_status "🧪 Testing deployment..."

    # Wait a moment for files to propagate
    sleep 5

    # Test main page
    if curl -s https://mrsvioletnoire.com/ | grep -q "Mrs. Violet Noire"; then
        print_success "✅ Main page is loading correctly"
    else
        print_warning "⚠️  Main page may not be loading properly"
    fi

    # Test CSS
    if curl -s https://mrsvioletnoire.com/css/style.css | grep -q "Mrs. Violet Noire"; then
        print_success "✅ CSS is loading correctly"
    else
        print_warning "⚠️  CSS may not be loading properly"
    fi
}

# Main execution
main() {
    print_status "🎭 Mrs. Violet Noire Website Deployment"
    print_status "======================================"

    check_credentials

    # Try FTP first (Hostinger shared hosting standard), fallback to FTPS
    if deploy_ftp 2>/dev/null; then
        print_success "Deployed via FTP"
    elif deploy_ftps 2>/dev/null; then
        print_success "Deployed via FTPS (FTP over SSL)"
    else
        print_error "Deployment failed. Please check your credentials and try again."
        exit 1
    fi

    test_deployment
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
