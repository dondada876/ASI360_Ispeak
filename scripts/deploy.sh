#!/bin/bash

# ========================================
# ASI360 iSpeak - Main Deployment Script
# ========================================
# This script automates the complete deployment
# of the ASI360 iSpeak system
# ========================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "========================================="
echo "  ASI360 iSpeak - Deployment Script"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    log_error ".env file not found!"
    log_info "Please copy .env.example to .env and fill in your credentials"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

log_success ".env file loaded successfully"

# ========================================
# Step 1: System Update & Dependencies
# ========================================
log_info "Step 1: Updating system and installing dependencies..."

apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
apt-get install -y \
    curl \
    wget \
    git \
    docker.io \
    docker-compose \
    postgresql-client \
    nginx \
    certbot \
    python3-certbot-nginx \
    jq \
    unzip

log_success "System updated and dependencies installed"

# ========================================
# Step 2: Docker Setup
# ========================================
log_info "Step 2: Setting up Docker..."

# Start Docker service
systemctl enable docker
systemctl start docker

# Verify Docker installation
if ! docker --version > /dev/null 2>&1; then
    log_error "Docker installation failed"
    exit 1
fi

log_success "Docker is running: $(docker --version)"

# ========================================
# Step 3: Setup Supabase Database
# ========================================
log_info "Step 3: Setting up Supabase database..."

if [ -x "./scripts/setup_supabase.sh" ]; then
    ./scripts/setup_supabase.sh
    log_success "Supabase database configured"
else
    log_warning "Supabase setup script not found or not executable"
    log_info "You'll need to manually run the database schema"
fi

# ========================================
# Step 4: SSL Certificates
# ========================================
log_info "Step 4: Setting up SSL certificates..."

if [ ! -z "${N8N_HOST:-}" ]; then
    log_info "Obtaining SSL certificate for ${N8N_HOST}..."

    # Stop nginx if running
    systemctl stop nginx || true

    # Get certificate
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "${ADMIN_EMAIL:-admin@${N8N_HOST}}" \
        -d "${N8N_HOST}" || {
        log_warning "Failed to obtain SSL certificate automatically"
        log_info "You may need to configure DNS first or use a self-signed certificate"
    }

    # Copy certificates to nginx directory
    if [ -f "/etc/letsencrypt/live/${N8N_HOST}/fullchain.pem" ]; then
        mkdir -p nginx/ssl
        cp "/etc/letsencrypt/live/${N8N_HOST}/fullchain.pem" nginx/ssl/
        cp "/etc/letsencrypt/live/${N8N_HOST}/privkey.pem" nginx/ssl/
        log_success "SSL certificates configured"
    else
        log_warning "SSL certificates not found, creating self-signed certificate..."
        mkdir -p nginx/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/privkey.pem \
            -out nginx/ssl/fullchain.pem \
            -subj "/C=US/ST=CA/L=Oakland/O=ASI360/CN=${N8N_HOST}"
        log_success "Self-signed SSL certificate created"
    fi
else
    log_warning "N8N_HOST not set, skipping SSL certificate setup"
fi

# ========================================
# Step 5: Start Docker Containers
# ========================================
log_info "Step 5: Starting Docker containers..."

# Stop any existing containers
docker-compose down || true

# Pull latest images
docker-compose pull

# Start services
docker-compose up -d

# Wait for services to be healthy
log_info "Waiting for services to start..."
sleep 10

# Check if N8N is running
if docker ps | grep -q asi360-n8n; then
    log_success "N8N container is running"
else
    log_error "N8N container failed to start"
    docker-compose logs n8n
    exit 1
fi

# ========================================
# Step 6: Import N8N Workflows
# ========================================
log_info "Step 6: Importing N8N workflows..."

if [ -x "./scripts/import_n8n_workflows.sh" ]; then
    sleep 20  # Wait for N8N to be fully ready
    ./scripts/import_n8n_workflows.sh
    log_success "N8N workflows imported"
else
    log_warning "Workflow import script not found"
    log_info "You'll need to manually import workflows from n8n/workflows/"
fi

# ========================================
# Step 7: Configure Firewall
# ========================================
log_info "Step 7: Configuring firewall..."

if command -v ufw > /dev/null 2>&1; then
    ufw --force enable
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw reload
    log_success "Firewall configured"
else
    log_warning "UFW not found, skipping firewall configuration"
fi

# ========================================
# Step 8: Setup Backup Cron Job
# ========================================
log_info "Step 8: Setting up automated backups..."

if [ -x "./scripts/backup.sh" ]; then
    # Add daily backup at 2 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $(pwd) && ./scripts/backup.sh >> /var/log/asi360-backup.log 2>&1") | crontab -
    log_success "Daily backup cron job configured"
else
    log_warning "Backup script not found"
fi

# ========================================
# Step 9: Health Check
# ========================================
log_info "Step 9: Running system health check..."

if [ -x "./scripts/health_check.sh" ]; then
    ./scripts/health_check.sh
else
    log_warning "Health check script not found"
fi

# ========================================
# Deployment Complete
# ========================================
echo ""
echo "========================================="
echo "  ✅ Deployment Complete!"
echo "========================================="
echo ""
log_success "ASI360 iSpeak has been successfully deployed"
echo ""
echo "📊 Access Points:"
echo "  • N8N Dashboard: https://${N8N_HOST:-localhost}:5678"
echo "  • N8N Credentials: ${N8N_BASIC_AUTH_USER} / [password from .env]"
echo ""
echo "🔧 Next Steps:"
echo "  1. Access N8N dashboard and verify workflows are active"
echo "  2. Configure Twilio webhooks to point to:"
echo "     https://${N8N_HOST}/webhook/twilio/inbound"
echo "  3. Add your first vendor to Supabase database"
echo "  4. Test sending a message"
echo ""
echo "📝 Important Files:"
echo "  • Logs: docker-compose logs -f n8n"
echo "  • Database: ${SUPABASE_URL}"
echo "  • Backups: /backups/"
echo ""
echo "🆘 Support:"
echo "  • Documentation: ./docs/"
echo "  • Health Check: ./scripts/health_check.sh"
echo "  • Troubleshooting: ./docs/TROUBLESHOOTING.md"
echo ""
echo "========================================="

# Save deployment timestamp
echo "Deployed at: $(date)" > .deployment_timestamp

exit 0
