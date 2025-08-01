# Security Configuration for Apache/Nginx

## Apache (.htaccess)

```apache
# Security Headers
Header always set X-Frame-Options "DENY"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set X-XSS-Protection "1; mode=block"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()"

# Content Security Policy
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.goodreads.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https://i.gr-assets.com https://s.gr-assets.com; frame-src https://www.goodreads.com; connect-src 'self' https://www.goodreads.com;"

# Prevent access to sensitive files
<FilesMatch "\.(env|key|pem|conf|config|bak|backup|swp|tmp)$">
    Require all denied
</FilesMatch>

# Hide server information
ServerTokens Prod
ServerSignature Off

# Prevent clickjacking
Header always append X-Frame-Options SAMEORIGIN

# HTTPS redirect (if using HTTPS)
# RewriteEngine On
# RewriteCond %{HTTPS} off
# RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

## Nginx Configuration

```nginx
# Security headers
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;

# Content Security Policy
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.goodreads.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https://i.gr-assets.com https://s.gr-assets.com; frame-src https://www.goodreads.com; connect-src 'self' https://www.goodreads.com;" always;

# Hide server information
server_tokens off;

# Prevent access to sensitive files
location ~ /\.(env|key|pem|conf|config|bak|backup|swp|tmp) {
    deny all;
    access_log off;
    log_not_found off;
}

# Prevent access to hidden files
location ~ /\. {
    deny all;
    access_log off;
    log_not_found off;
}

# Rate limiting
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;

# SSL Configuration (if using HTTPS)
# ssl_protocols TLSv1.2 TLSv1.3;
# ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
# ssl_prefer_server_ciphers off;
# ssl_session_cache shared:SSL:10m;
# ssl_session_timeout 10m;
```

## Docker Security Configuration

```dockerfile
# Use non-root user
FROM nginx:alpine
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Copy files with correct permissions
COPY --chown=nginx:nginx . /usr/share/nginx/html/

# Run as non-root
USER nginx

# Expose only necessary port
EXPOSE 8080

# Security-focused nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
```

## Environment Variables Security

```bash
# Use in your deployment scripts

# Set secure file permissions
chmod 600 config/secrets.env
chmod 700 config/

# Environment variable validation
check_required_vars() {
    for var in "$@"; do
        if [ -z "${!var}" ]; then
            echo "Error: Required environment variable $var is not set"
            exit 1
        fi
    done
}

# Example usage
check_required_vars "HOSTINGER_API_TOKEN" "GOODREADS_API_KEY"
```

## Production Security Checklist

- [ ] HTTPS enabled with valid SSL certificate
- [ ] Security headers configured
- [ ] Content Security Policy (CSP) implemented
- [ ] Sensitive files protected from web access
- [ ] Server information hidden
- [ ] Rate limiting configured
- [ ] Regular security updates applied
- [ ] Monitoring and logging enabled
- [ ] Backup and recovery procedures tested
- [ ] Access controls properly configured

## Monitoring and Alerting

```bash
# Example log monitoring for security events
tail -f /var/log/nginx/access.log | grep -E "(40[1-9]|50[0-9])" | while read line; do
    echo "Security alert: $line" | mail -s "Security Alert" admin@mrs-violet-noire.com
done
```
