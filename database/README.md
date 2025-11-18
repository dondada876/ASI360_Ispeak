# Database

This directory contains the complete database schema and migrations for the ASI360 iSpeak system.

## Files

- **schema.sql** - Complete PostgreSQL database schema with all tables, indexes, triggers, and functions
- **migrations/** - Database migration scripts (applied sequentially)
- **seed/** - Seed data for development and testing

## Database Structure

The database includes 8 main tables:

1. **vendor_profiles** - Vendor information and contact details
2. **conversations** - All messages (inbound/outbound) with translations
3. **tasks** - Action items extracted from conversations
4. **compliance_requirements** - Compliance requirement templates
5. **vendor_compliance** - Vendor-specific compliance tracking
6. **media_files** - Audio, image, and document storage metadata
7. **message_templates** - Multilingual message templates
8. **system_events** - Complete audit trail

## Setup

### Using Supabase (Recommended)

```bash
# Run the setup script
./scripts/setup_supabase.sh
```

### Manual Setup

```bash
# Connect to your database
psql $DATABASE_URL -f database/schema.sql
```

## Key Features

- **Row-Level Security (RLS)** - Vendor data isolation
- **Full-Text Search** - Fast message search across conversations
- **Automatic Triggers** - Auto-update timestamps, task creation from conversations
- **Helper Functions** - Compliance scoring, analytics, bulk operations
- **Materialized Views** - Fast reporting and dashboards

## Maintenance

### Backup

```bash
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql
```

### Restore

```bash
psql $DATABASE_URL < backup_20250117.sql
```

## Querying Examples

### Get vendor statistics

```sql
SELECT * FROM get_vendor_stats('vendor-uuid-here');
```

### Check compliance status

```sql
SELECT * FROM compliance_dashboard WHERE days_until_expiration < 30;
```

### Find overdue tasks

```sql
SELECT * FROM tasks WHERE status = 'overdue' ORDER BY due_date;
```
