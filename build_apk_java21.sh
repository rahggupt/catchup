#!/bin/bash

# Script to build release APK with Java 21 and environment variables

# Set Java 21 as the Java for this build
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

echo "☕ Using Java 21 for build:"
java --version
echo ""

# Load environment variables from .env file
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy .env.example to .env and fill in your values"
    exit 1
fi

echo "📦 Building CatchUp Release APK..."
echo ""

# Read .env file and export variables
export $(grep -v '^#' .env | xargs)

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo ""
echo "🔨 Building release APK with environment variables..."
echo "This may take 5-10 minutes on first build..."
echo ""

# Build release APK with environment variables
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_URL="$QDRANT_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ APK built successfully!"
    echo ""
    echo "📍 APK Location:"
    echo "   build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 APK Size:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print "   " $5}'
    echo ""
    echo "📱 To install on your phone:"
    echo ""
    echo "Method 1 - Via USB (Phone connected):"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Method 2 - Transfer to phone:"
    echo "   1. Find the APK at: build/app/outputs/flutter-apk/app-release.apk"
    echo "   2. Transfer to your phone (email, AirDrop, Google Drive, etc.)"
    echo "   3. On phone: tap the APK to install"
    echo "   4. Enable 'Install from Unknown Sources' if prompted"
    echo ""
    echo "Method 3 - Open in Finder:"
    open build/app/outputs/flutter-apk/
else
    echo ""
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi

