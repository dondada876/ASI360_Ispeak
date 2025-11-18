# Scripts

Deployment and utility scripts for ASI360 iSpeak.

## Main Scripts

### deploy.sh
**Main deployment script - runs complete system setup**

```bash
sudo ./scripts/deploy.sh
```

This script:
- Updates system packages
- Installs Docker and dependencies
- Configures Supabase database
- Sets up SSL certificates
- Starts all services
- Imports N8N workflows
- Configures firewall and backups

### setup_droplet.sh
**Initial DigitalOcean droplet configuration**

```bash
sudo ./scripts/setup_droplet.sh
```

Run this FIRST on a new droplet before deploying.

### setup_supabase.sh
**Database schema deployment**

```bash
./scripts/setup_supabase.sh
```

Deploys complete database schema to Supabase.

### import_n8n_workflows.sh
**Import all N8N workflows**

```bash
./scripts/import_n8n_workflows.sh
```

Imports all workflows from `n8n/workflows/` directory.

### backup.sh
**Automated backup script**

```bash
./scripts/backup.sh
```

Backs up:
- Supabase database
- N8N workflows
- Configuration files

Runs daily via cron at 2 AM.

### health_check.sh
**System health monitoring**

```bash
./scripts/health_check.sh
```

Checks:
- Docker status
- N8N status
- Database connectivity
- Disk space
- Memory usage
- SSL certificates
- Recent logs

## Usage

### First Time Setup

```bash
# 1. Setup droplet
sudo ./scripts/setup_droplet.sh

# 2. Clone repository and configure .env
git clone https://github.com/yourusername/ASI360_Ispeak.git
cd ASI360_Ispeak
cp .env.example .env
nano .env  # Edit with your credentials

# 3. Deploy everything
sudo ./scripts/deploy.sh
```

### Maintenance

```bash
# Run health check
./scripts/health_check.sh

# Manual backup
./scripts/backup.sh

# Re-import workflows after changes
./scripts/import_n8n_workflows.sh
```

## Cron Jobs

The deploy script automatically sets up:

```cron
# Daily backup at 2 AM
0 2 * * * cd /path/to/ASI360_Ispeak && ./scripts/backup.sh
```

Add additional jobs:

```bash
crontab -e
```

## Logs

View script logs:

```bash
# Backup logs
tail -f /var/log/asi360-backup.log

# Docker logs
docker-compose logs -f

# N8N logs
docker logs -f asi360-n8n
```
