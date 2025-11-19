#!/bin/bash

# Script to build APK with Java 21 and environment variables
# Usage: 
#   ./build_apk_java21.sh           # Build production APK (no debug logs)
#   ./build_apk_java21.sh --debug   # Build APK with debug logs enabled

# Parse arguments
DEBUG_MODE=false
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --help)
            echo "Usage: ./build_apk_java21.sh [--debug]"
            echo ""
            echo "Options:"
            echo "  --debug    Enable debug mode (shows debug logs in Profile settings)"
            echo "  --help     Show this help message"
            exit 0
            ;;
    esac
done

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

if [ "$DEBUG_MODE" = true ]; then
    echo "📦 Building CatchUp APK with DEBUG MODE ENABLED..."
    echo "⚠️  Debug logs will be visible in Profile > Debug Settings"
else
    echo "📦 Building CatchUp Release APK (production mode)..."
    echo "ℹ️  Debug logs disabled (production build)"
fi
echo ""

# Read .env file and export variables
export $(grep -v '^#' .env | xargs)

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo ""
echo "🔨 Building APK with environment variables..."
echo "This may take 5-10 minutes on first build..."
echo ""

# Build APK with environment variables
# Conditionally add DEBUG_MODE flag
if [ "$DEBUG_MODE" = true ]; then
    flutter build apk --release \
      --dart-define=SUPABASE_URL="$SUPABASE_URL" \
      --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
      --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
      --dart-define=QDRANT_URL="$QDRANT_URL" \
      --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
      --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY" \
      --dart-define=DEBUG_MODE=true
else
    flutter build apk --release \
      --dart-define=SUPABASE_URL="$SUPABASE_URL" \
      --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
      --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
      --dart-define=QDRANT_URL="$QDRANT_URL" \
      --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
      --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY"
fi

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    
    # Rename APK based on build mode
    if [ "$DEBUG_MODE" = true ]; then
        mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/app-release-debug.apk
        APK_NAME="app-release-debug.apk"
        echo "✅ APK built successfully with DEBUG MODE!"
        echo ""
        echo "🐛 Debug Features Enabled:"
        echo "   • Debug logs visible in Profile > Debug Settings"
        echo "   • Download and share logs for troubleshooting"
        echo "   • All errors automatically captured"
    else
        APK_NAME="app-release.apk"
        echo "✅ APK built successfully (production mode)!"
        echo ""
        echo "📦 Production Build:"
        echo "   • Debug logs hidden from users"
        echo "   • Optimized for end users"
    fi
    
    echo ""
    echo "📍 APK Location:"
    echo "   build/app/outputs/flutter-apk/$APK_NAME"
    echo ""
    echo "📊 APK Size:"
    ls -lh build/app/outputs/flutter-apk/$APK_NAME | awk '{print "   " $5}'
    echo ""
    echo "📱 To install on your phone:"
    echo ""
    echo "Method 1 - Via USB (Phone connected):"
    echo "   adb install build/app/outputs/flutter-apk/$APK_NAME"
    echo ""
    echo "Method 2 - Transfer to phone:"
    echo "   1. Find the APK at: build/app/outputs/flutter-apk/$APK_NAME"
    echo "   2. Transfer to your phone (email, AirDrop, Google Drive, etc.)"
    echo "   3. On phone: tap the APK to install"
    echo "   4. Enable 'Install from Unknown Sources' if prompted"
    echo ""
    echo "Method 3 - Open in Finder:"
    open build/app/outputs/flutter-apk/
    echo ""
    
    if [ "$DEBUG_MODE" = true ]; then
        echo "💡 Note: Debug section will only appear in Profile settings!"
    fi
else
    echo ""
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi

