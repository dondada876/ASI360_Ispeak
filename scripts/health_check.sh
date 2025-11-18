#!/bin/bash
# Health Check Script for ASI360 iSpeak
set +e  # Don't exit on error for health checks

echo "========================================="
echo "  ASI360 iSpeak - System Health Check"
echo "========================================="
echo ""

source .env 2>/dev/null || echo "Warning: .env file not found"

# Check Docker
echo "🐳 Docker Status:"
if docker ps > /dev/null 2>&1; then
    echo "  ✅ Docker is running"
    echo "  📦 Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep asi360 || echo "  ⚠️  No ASI360 containers running"
else
    echo "  ❌ Docker is not running"
fi
echo ""

# Check N8N
echo "⚙️  N8N Status:"
if docker ps | grep -q asi360-n8n; then
    echo "  ✅ N8N container is running"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/healthz | grep -q "200"; then
        echo "  ✅ N8N is responding"
    else
        echo "  ⚠️  N8N is not responding on port 5678"
    fi
else
    echo "  ❌ N8N container is not running"
fi
echo ""

# Check Database
echo "🗄️  Database Status:"
if [ ! -z "${SUPABASE_URL}" ]; then
    if curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}" | grep -q "200"; then
        echo "  ✅ Supabase is accessible"
    else
        echo "  ⚠️  Supabase is not accessible"
    fi
else
    echo "  ⚠️  SUPABASE_URL not configured"
fi
echo ""

# Check Disk Space
echo "💾 Disk Space:"
df -h / | awk 'NR==2 {print "  📊 Used: "$3" / "$2" ("$5" used)"}'
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "  ⚠️  Disk usage is above 80%"
else
    echo "  ✅ Disk space is adequate"
fi
echo ""

# Check Memory
echo "🧠 Memory Usage:"
free -h | awk 'NR==2 {print "  📊 Used: "$3" / "$2}'
echo ""

# Check Nginx
echo "🌐 Nginx Status:"
if systemctl is-active --quiet nginx; then
    echo "  ✅ Nginx is running"
    if nginx -t 2>/dev/null; then
        echo "  ✅ Nginx configuration is valid"
    else
        echo "  ⚠️  Nginx configuration has errors"
    fi
else
    echo "  ⚠️  Nginx is not running"
fi
echo ""

# Check SSL Certificates
echo "🔐 SSL Certificates:"
if [ -f "nginx/ssl/fullchain.pem" ]; then
    EXPIRY=$(openssl x509 -enddate -noout -in nginx/ssl/fullchain.pem | cut -d= -f2)
    echo "  ✅ Certificate found"
    echo "  📅 Expires: $EXPIRY"
else
    echo "  ⚠️  No SSL certificate found"
fi
echo ""

# Check Recent Logs
echo "📋 Recent N8N Logs (last 10 lines):"
if docker ps | grep -q asi360-n8n; then
    docker logs --tail 10 asi360-n8n 2>&1 | head -n 10
else
    echo "  ⚠️  N8N container not running"
fi
echo ""

echo "========================================="
echo "  Health Check Complete"
echo "========================================="
