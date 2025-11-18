#!/bin/bash
# Import N8N Workflows
set -e

echo "Importing N8N workflows..."

source .env

WORKFLOW_DIR="./n8n/workflows"

if [ ! -d "$WORKFLOW_DIR" ]; then
    echo "❌ Workflow directory not found: $WORKFLOW_DIR"
    exit 1
fi

# Wait for N8N to be ready
echo "⏳ Waiting for N8N to be ready..."
for i in {1..30}; do
    if curl -s -u "${N8N_BASIC_AUTH_USER}:${N8N_BASIC_AUTH_PASSWORD}" \
        "http://localhost:5678/healthz" > /dev/null 2>&1; then
        echo "✅ N8N is ready"
        break
    fi
    echo "  Attempt $i/30..."
    sleep 2
done

# Import each workflow
IMPORTED=0
FAILED=0

for workflow in "$WORKFLOW_DIR"/*.json; do
    if [ -f "$workflow" ]; then
        WORKFLOW_NAME=$(basename "$workflow")
        echo "📥 Importing: $WORKFLOW_NAME"

        # Copy workflow into container
        docker cp "$workflow" asi360-n8n:/tmp/workflow.json

        # Import using N8N CLI
        if docker exec asi360-n8n n8n import:workflow --input=/tmp/workflow.json; then
            echo "  ✅ Successfully imported: $WORKFLOW_NAME"
            ((IMPORTED++))
        else
            echo "  ❌ Failed to import: $WORKFLOW_NAME"
            ((FAILED++))
        fi
    fi
done

echo ""
echo "========================================="
echo "  Import Summary"
echo "========================================="
echo "✅ Successfully imported: $IMPORTED workflows"
if [ $FAILED -gt 0 ]; then
    echo "❌ Failed to import: $FAILED workflows"
fi
echo ""
echo "🌐 Access N8N at: https://${N8N_HOST}:5678"
echo "🔑 Username: ${N8N_BASIC_AUTH_USER}"
echo ""
