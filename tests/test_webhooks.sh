#!/bin/bash
# Test Webhook Endpoints

set -e
source .env

echo "========================================="
echo "  Testing Webhook Endpoints"
echo "========================================="
echo ""

# Test health endpoint
echo "📝 Test 1: Health check endpoint"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/health")

if [ "$STATUS" = "200" ]; then
    echo "  ✅ Health check passed (HTTP $STATUS)"
else
    echo "  ❌ Health check failed (HTTP $STATUS)"
    exit 1
fi

echo ""

# Test N8N health endpoint
echo "📝 Test 2: N8N health endpoint"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5678/healthz")

if [ "$STATUS" = "200" ]; then
    echo "  ✅ N8N is responding (HTTP $STATUS)"
else
    echo "  ⚠️  N8N health check returned HTTP $STATUS"
fi

echo ""

# Test send message endpoint (requires authentication)
echo "📝 Test 3: Send message endpoint (structure test)"
RESPONSE=$(curl -s -X POST "http://localhost:5678/webhook/send-message" \
  -H "Content-Type: application/json" \
  -d '{"vendor_id": "test-vendor", "message": "Test message"}')

if [ ! -z "$RESPONSE" ]; then
    echo "  ✅ Endpoint is responding"
    echo "  📄 Response: $RESPONSE"
else
    echo "  ⚠️  Endpoint returned empty response (may need authentication)"
fi

echo ""
echo "========================================="
echo "  ✅ Webhook tests completed!"
echo "========================================="
