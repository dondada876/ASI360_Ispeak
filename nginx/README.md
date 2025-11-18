# Nginx Configuration

Reverse proxy configuration for ASI360 iSpeak N8N instance.

## Files

- **nginx.conf** - Main Nginx configuration
- **ssl/** - SSL certificates directory

## Features

- **HTTPS Redirect** - All HTTP traffic redirected to HTTPS
- **SSL/TLS** - Secure connections with TLS 1.2+
- **Rate Limiting** - Protection against abuse
- **Reverse Proxy** - Forwards requests to N8N
- **WebSocket Support** - For N8N real-time features
- **Security Headers** - HSTS, X-Frame-Options, etc.

## SSL Certificates

### Using Let's Encrypt (Automatic)

The deploy script automatically obtains certificates:

```bash
sudo ./scripts/deploy.sh
```

### Manual Let's Encrypt

```bash
sudo certbot --nginx -d your-domain.com
```

### Self-Signed (Development)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/privkey.pem \
  -out nginx/ssl/fullchain.pem
```

## Configuration

### Rate Limits

**Webhooks:** 10 requests/second (burst: 20)
**API:** 30 requests/second (burst: 50)

Adjust in `nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=webhook_limit:10m rate=10r/s;
```

### File Upload Size

Current limit: 50MB

Change in `nginx.conf`:

```nginx
client_max_body_size 50M;
```

## Testing Configuration

```bash
# Test configuration
sudo nginx -t

# Reload after changes
sudo nginx -s reload
```

## Endpoints

- **/** - N8N Dashboard
- **/webhook/** - N8N webhooks
- **/api/** - N8N API
- **/health** - Health check endpoint

## Monitoring

### Access Logs

```bash
tail -f /var/log/nginx/access.log
```

### Error Logs

```bash
tail -f /var/log/nginx/error.log
```

### Status Page

Access at: `http://localhost/nginx_status` (internal only)

## Troubleshooting

### Certificate Errors

```bash
# Check certificate
openssl x509 -in nginx/ssl/fullchain.pem -text -noout

# Renew Let's Encrypt
sudo certbot renew
```

### Port Already in Use

```bash
# Find process using port 443
sudo lsof -i :443

# Stop conflicting service
sudo systemctl stop apache2  # if Apache is running
```
