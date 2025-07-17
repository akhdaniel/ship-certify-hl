#!/bin/bash

echo "🚢 Testing BKI Ship Owner API..."
echo "================================="

# Test 1: Create a new ship owner
echo "Test 1: Creating new ship owner..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/shipowners \
  -H "Content-Type: application/json" \
  -d '{
    "shipOwnerId": "TEST_'$(date +%s)'",
    "address": "test'$(date +%s)'@example.com",
    "name": "Test Ship Owner",
    "companyName": "Test Maritime Company"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ Ship owner creation successful!"
    echo "Response: $RESPONSE"
else
    echo "❌ Ship owner creation failed!"
    echo "Response: $RESPONSE"
fi

echo ""

# Test 2: Query all ship owners
echo "Test 2: Querying all ship owners..."
RESPONSE=$(curl -s -X GET http://localhost:3000/api/shipowners)

if echo "$RESPONSE" | grep -q '"success":true'; then
    COUNT=$(echo "$RESPONSE" | grep -o '"Key"' | wc -l)
    echo "✅ Ship owner query successful! Found $COUNT ship owners."
else
    echo "❌ Ship owner query failed!"
    echo "Response: $RESPONSE"
fi

echo ""
echo "🎉 API testing completed!"
