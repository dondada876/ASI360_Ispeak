#!/bin/bash
# Backup Script for ASI360 iSpeak
set -e

BACKUP_DIR="/backups/asi360-ispeak"
DATE=$(date +%Y%m%d_%H%M%S)
source .env

mkdir -p "${BACKUP_DIR}"

echo "🔄 Starting backup at $(date)"

# Backup Supabase database
echo "📊 Backing up Supabase database..."
pg_dump "${SUPABASE_URL}/db/postgres" > "${BACKUP_DIR}/database_${DATE}.sql"

# Backup N8N workflows
echo "⚙️ Backing up N8N workflows..."
docker exec asi360-n8n n8n export:workflow --all --output="/tmp/workflows_${DATE}.json" || true
docker cp asi360-n8n:/tmp/workflows_${DATE}.json "${BACKUP_DIR}/" || true

# Backup environment config (without sensitive data)
echo "🔐 Backing up configuration..."
cp .env "${BACKUP_DIR}/env_backup_${DATE}.txt"

# Compress backups older than 7 days
find "${BACKUP_DIR}" -name "*.sql" -mtime +7 -exec gzip {} \;

# Remove backups older than 30 days
find "${BACKUP_DIR}" -name "*.gz" -mtime +30 -delete

echo "✅ Backup completed: ${BACKUP_DIR}/database_${DATE}.sql"
echo "📦 Backup size: $(du -sh ${BACKUP_DIR} | cut -f1)"
