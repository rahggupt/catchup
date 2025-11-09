#!/bin/bash

# Script to run Flutter app on Android with environment variables from .env file

# Load environment variables from .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and fill in your values"
    exit 1
fi

# Read .env file and export variables
export $(grep -v '^#' .env | xargs)

# Check if Android device is connected
echo "Checking for connected Android devices..."
flutter devices

# Run Flutter on Android with dart-define flags
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_URL="$QDRANT_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY"

