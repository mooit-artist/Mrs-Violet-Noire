#!/usr/bin/env bash

# Mrs. Violet Noire - Local Security Scanner
# Run comprehensive security checks locally before committing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}🔒 Mrs. Violet Noire Security Scanner${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "----------------------------------------"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check for sensitive files
print_section "1. Checking for Sensitive Files"

sensitive_patterns=(
    "*.key"
    "*.pem"
    "*.p12"
    "*.pfx"
    "*.env"
    "*secret*"
    "*password*"
    "*token*"
    "id_rsa"
    "id_dsa"
    "id_ecdsa"
    "id_ed25519"
)

found_sensitive=false
for pattern in "${sensitive_patterns[@]}"; do
    if find . -name "$pattern" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.terraform/*" | grep -q .; then
        print_warning "Found potentially sensitive files matching: $pattern"
        find . -name "$pattern" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.terraform/*"
        found_sensitive=true
    fi
done

if [ "$found_sensitive" = false ]; then
    print_success "No sensitive files detected"
fi

# Check .gitignore coverage
print_section "2. Checking .gitignore Coverage"

if [ -f ".gitignore" ]; then
    required_ignores=(
        "*.env"
        "*.key"
        "*.pem"
        "node_modules/"
        ".DS_Store"
        "*.log"
        ".terraform/"
        "terraform.tfstate*"
        "*.backup"
    )
    
    missing_ignores=()
    for ignore in "${required_ignores[@]}"; do
        if ! grep -q "$ignore" .gitignore; then
            missing_ignores+=("$ignore")
        fi
    done
    
    if [ ${#missing_ignores[@]} -eq 0 ]; then
        print_success ".gitignore has good coverage"
    else
        print_warning ".gitignore missing patterns:"
        for missing in "${missing_ignores[@]}"; do
            echo "  - $missing"
        done
    fi
else
    print_error ".gitignore file not found"
fi

# Check for hardcoded secrets in source files
print_section "3. Scanning for Hardcoded Secrets"

secret_patterns=(
    "password\s*=\s*['\"][^'\"]+['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "secret\s*=\s*['\"][^'\"]+['\"]"
    "token\s*=\s*['\"][^'\"]+['\"]"
    "aws[_-]?access[_-]?key"
    "aws[_-]?secret[_-]?key"
    "BEGIN\s+(RSA\s+)?PRIVATE\s+KEY"
    "[a-zA-Z0-9]{20,}"
)

found_secrets=false
for pattern in "${secret_patterns[@]}"; do
    if grep -r -i -E "$pattern" --include="*.js" --include="*.html" --include="*.css" --include="*.json" --include="*.md" --exclude-dir=node_modules --exclude-dir=.git . >/dev/null 2>&1; then
        print_warning "Potential secret pattern found: $pattern"
        grep -r -i -E "$pattern" --include="*.js" --include="*.html" --include="*.css" --include="*.json" --include="*.md" --exclude-dir=node_modules --exclude-dir=.git . || true
        found_secrets=true
    fi
done

if [ "$found_secrets" = false ]; then
    print_success "No hardcoded secrets detected"
fi

# Check npm dependencies for vulnerabilities
print_section "4. Checking Node.js Dependencies"

if [ -f "package.json" ]; then
    if command_exists npm; then
        print_success "Running npm audit..."
        if npm audit --audit-level moderate; then
            print_success "No moderate or higher vulnerabilities found"
        else
            print_warning "Vulnerabilities found - run 'npm audit fix' to resolve"
        fi
    else
        print_warning "npm not found, skipping dependency check"
    fi
else
    print_warning "No package.json found, skipping npm audit"
fi

# Check file permissions
print_section "5. Checking File Permissions"

executable_files=(
    "scripts/*.sh"
    "*.sh"
)

for pattern in "${executable_files[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            if [ -x "$file" ]; then
                print_success "Script $file has correct executable permissions"
            else
                print_warning "Script $file is not executable (run: chmod +x $file)"
            fi
        fi
    done
done

# Check for security headers in HTML files
print_section "6. Checking Security Headers in HTML"

if find . -name "*.html" -not -path "./node_modules/*" | grep -q .; then
    security_headers=(
        "Content-Security-Policy"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "Referrer-Policy"
        "Permissions-Policy"
    )
    
    html_files=$(find . -name "*.html" -not -path "./node_modules/*")
    
    for header in "${security_headers[@]}"; do
        if grep -l "$header" $html_files >/dev/null 2>&1; then
            print_success "Security header '$header' found in HTML files"
        else
            print_warning "Security header '$header' not found in HTML files"
        fi
    done
else
    print_warning "No HTML files found to check for security headers"
fi

# Check Terraform files if they exist
print_section "7. Checking Terraform Security"

if [ -d "terraform" ] && [ "$(ls -A terraform/*.tf 2>/dev/null)" ]; then
    if command_exists terraform; then
        cd terraform
        if terraform validate; then
            print_success "Terraform configuration is valid"
        else
            print_error "Terraform validation failed"
        fi
        cd ..
    else
        print_warning "terraform command not found, skipping validation"
    fi
    
    # Check for common Terraform security issues
    if grep -r "password.*=" terraform/ >/dev/null 2>&1; then
        print_warning "Potential hardcoded passwords in Terraform files"
    fi
    
    if grep -r "secret.*=" terraform/ >/dev/null 2>&1; then
        print_warning "Potential hardcoded secrets in Terraform files"
    fi
else
    print_warning "No Terraform files found, skipping Terraform checks"
fi

# Summary
print_section "Security Scan Complete"

echo ""
echo -e "${BLUE}📋 Security Recommendations:${NC}"
echo "1. Ensure all sensitive data is in environment variables or secure vaults"
echo "2. Keep dependencies updated and regularly run security audits"
echo "3. Implement Content Security Policy (CSP) headers"
echo "4. Use HTTPS in production and set secure cookie flags"
echo "5. Regularly rotate API keys and access tokens"
echo "6. Enable branch protection rules and require PR reviews"
echo "7. Set up automated security scanning in CI/CD pipeline"
echo ""

echo -e "${GREEN}🔒 Security scan completed successfully!${NC}"
echo "Run this script regularly or set it up as a pre-commit hook."
