# Security and API Management

## Secure Token Storage

Your API tokens are now securely stored in the `config/` directory:

- `config/secrets.env` - Contains your actual API keys (excluded from git)
- `config/secrets.env.template` - Template file for setting up credentials

## Using the Hostinger API

To use the Hostinger API securely:

```bash
# Load API credentials
source scripts/hostinger-api.sh

# Test the API connection
test_hostinger_api

# Make API calls
hostinger_api '/vps'
hostinger_api '/domains'
```

## Security Features

- ✅ API tokens stored in secure `config/secrets.env` (chmod 600)
- ✅ Comprehensive `.gitignore` excludes all sensitive files
- ✅ Template file available for easy setup
- ✅ Helper script with built-in error handling

## File Permissions

The secrets file has restricted permissions (600) - only you can read/write it.

## Setup for New Environments

1. Copy the template: `cp config/secrets.env.template config/secrets.env`
2. Edit with your actual API keys
3. Source the helper script: `source scripts/hostinger-api.sh`
4. Test the connection: `test_hostinger_api`
