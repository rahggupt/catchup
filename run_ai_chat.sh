#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
else
  echo "Error: .env file not found"
  exit 1
fi

# Check if required variables are set
if [ -z "$GEMINI_API_KEY" ] || [ -z "$QDRANT_API_URL" ] || [ -z "$QDRANT_API_KEY" ] || [ -z "$HUGGING_FACE_API_KEY" ]; then
  echo "Error: Missing required environment variables in .env"
  echo "Required: GEMINI_API_KEY, QDRANT_API_URL, QDRANT_API_KEY, HUGGING_FACE_API_KEY"
  exit 1
fi

echo "🚀 Starting Flutter app with AI Chat enabled..."
echo "📝 Using:"
echo "  - Gemini API (AI responses)"
echo "  - Qdrant (vector database)"
echo "  - Hugging Face (embeddings)"

# Run Flutter with dart-defines for environment variables
flutter run -d chrome \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_API_URL="$QDRANT_API_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGING_FACE_API_KEY="$HUGGING_FACE_API_KEY"

