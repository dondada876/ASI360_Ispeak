#!/bin/bash
# DigitalOcean Droplet Initial Setup
set -e

echo "========================================="
echo "  DigitalOcean Droplet Setup"
echo "========================================="

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl wget git vim \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
apt-get install -y docker-compose

# Setup firewall
ufw --force enable
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp

# Create swap file (if not exists)
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi

# Setup automatic security updates
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo "✅ Droplet setup complete!"
echo ""
echo "Next steps:"
echo "1. Clone your repository"
echo "2. Copy .env.example to .env and configure"
echo "3. Run ./scripts/deploy.sh"
