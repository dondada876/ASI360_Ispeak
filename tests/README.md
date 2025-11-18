# Tests

Test scripts for ASI360 iSpeak system.

## Test Scripts

### test_translation.sh
Tests DeepL translation API integration.

```bash
./tests/test_translation.sh
```

### test_webhooks.sh
Tests webhook endpoints and message flow.

```bash
./tests/test_webhooks.sh
```

### test_database.sh
Tests database connectivity and queries.

```bash
./tests/test_database.sh
```

## Running Tests

### Run All Tests

```bash
./tests/run_all_tests.sh
```

### Run Individual Tests

```bash
# Translation only
./tests/test_translation.sh

# Webhooks only
./tests/test_webhooks.sh

# Database only
./tests/test_database.sh
```

## Writing Tests

Tests use bash with curl for API testing.

Example test:

```bash
#!/bin/bash
source ../.env

echo "Testing webhook endpoint..."
RESPONSE=$(curl -s -X POST \
  https://${N8N_HOST}/webhook/send-message \
  -H "Content-Type: application/json" \
  -d '{"vendor_id": "test-123", "message": "Test message"}')

if echo "$RESPONSE" | grep -q "success"; then
  echo "✅ Test passed"
else
  echo "❌ Test failed"
  exit 1
fi
```

## Continuous Integration

TODO: Add GitHub Actions workflow for automated testing.
