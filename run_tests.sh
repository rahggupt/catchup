#!/bin/bash

# API Test Suite Runner
# Loads environment variables and runs comprehensive API tests

echo "🧪 CatchUp API Test Suite Runner"
echo "=================================="
echo ""

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
  echo "✅ Loaded environment variables from .env"
else
  echo "⚠️  Warning: .env file not found"
  echo "   Tests will use default values or skip"
fi

echo ""
echo "📋 Test Configuration:"
echo "   Supabase URL: ${SUPABASE_URL:0:30}..."
echo "   Gemini API Key: ${GEMINI_API_KEY:+Set}${GEMINI_API_KEY:-Not Set}"
echo "   Qdrant API URL: ${QDRANT_API_URL:+Set}${QDRANT_API_URL:-Not Set}"
echo "   Hugging Face API Key: ${HUGGING_FACE_API_KEY:+Set}${HUGGING_FACE_API_KEY:-Not Set}"
echo ""

# Run Flutter tests with environment variables
echo "🚀 Running API tests..."
echo ""

flutter test test/api_test_suite.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_API_URL="$QDRANT_API_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGING_FACE_API_KEY="$HUGGING_FACE_API_KEY" \
  --reporter expanded

echo ""
echo "✅ Test suite complete!"

