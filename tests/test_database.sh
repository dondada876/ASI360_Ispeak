#!/bin/bash
# Test Database Connectivity and Queries

set -e
source .env

echo "========================================="
echo "  Testing Database Connectivity"
echo "========================================="
echo ""

# Test basic connectivity
echo "📝 Test 1: Database connection"
if psql "${SUPABASE_URL}/db/postgres" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "  ✅ Database connection successful"
else
    echo "  ❌ Database connection failed"
    exit 1
fi

echo ""

# Test tables exist
echo "📝 Test 2: Verify core tables exist"
TABLES=$(psql "${SUPABASE_URL}/db/postgres" -t -c "\dt" | grep -c "vendor_profiles\|conversations\|tasks" || echo "0")

if [ "$TABLES" -ge 3 ]; then
    echo "  ✅ Core tables found"
else
    echo "  ❌ Core tables missing (found $TABLES)"
    exit 1
fi

echo ""

# Test helper functions
echo "📝 Test 3: Test helper functions"
if psql "${SUPABASE_URL}/db/postgres" -c "SELECT get_database_stats();" > /dev/null 2>&1; then
    echo "  ✅ Helper functions working"
else
    echo "  ⚠️  Some helper functions may not be available"
fi

echo ""
echo "========================================="
echo "  ✅ Database tests completed!"
echo "========================================="
