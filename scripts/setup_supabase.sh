#!/bin/bash
# Setup Supabase Database Schema
set -e
source .env

echo "Setting up Supabase database..."

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL client..."
    apt-get install -y postgresql-client
fi

# Construct database connection string
DB_URL="${SUPABASE_URL/https:\/\//}/db/postgres"

# Run schema migration
echo "Running database schema..."
psql "${SUPABASE_URL}/db/postgres?sslmode=require" \
    -U postgres \
    -f database/schema.sql

echo "✅ Database schema deployed successfully"
echo "✅ Tables created: vendor_profiles, conversations, tasks, compliance_requirements, etc."
echo ""
echo "Next: Add your first vendor with:"
echo "psql \$SUPABASE_URL -c \"INSERT INTO vendor_profiles (business_name, primary_contact_name, phone_number, primary_language) VALUES ('Test Vendor', 'John Doe', '+15555551234', 'es');\""
