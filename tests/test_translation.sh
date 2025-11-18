#!/bin/bash
# Test DeepL Translation API

set -e
source .env

echo "========================================="
echo "  Testing DeepL Translation API"
echo "========================================="
echo ""

# Test English to Spanish
echo "📝 Test 1: English to Spanish translation"
RESPONSE=$(curl -s -X POST "https://api-free.deepl.com/v2/translate" \
  -H "Authorization: DeepL-Auth-Key ${DEEPL_API_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "text=Hello, please submit your insurance certificate by Friday." \
  -d "target_lang=ES")

if echo "$RESPONSE" | grep -q "Hola"; then
    echo "  ✅ Translation successful"
    echo "  📄 Result: $(echo $RESPONSE | jq -r '.translations[0].text')"
else
    echo "  ❌ Translation failed"
    echo "  📄 Response: $RESPONSE"
    exit 1
fi

echo ""

# Test Spanish to English
echo "📝 Test 2: Spanish to English translation"
RESPONSE=$(curl -s -X POST "https://api-free.deepl.com/v2/translate" \
  -H "Authorization: DeepL-Auth-Key ${DEEPL_API_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "text=Hola, necesito ayuda con mi equipo." \
  -d "target_lang=EN")

if echo "$RESPONSE" | grep -q "Hello"; then
    echo "  ✅ Translation successful"
    echo "  📄 Result: $(echo $RESPONSE | jq -r '.translations[0].text')"
else
    echo "  ❌ Translation failed"
    echo "  📄 Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================="
echo "  ✅ All translation tests passed!"
echo "========================================="
