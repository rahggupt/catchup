#!/bin/bash

# CatchUp App Icon Generator
# Run this script after saving the app icon to assets/images/app_icon.png

set -e

echo "🎨 CatchUp Icon Generator"
echo "========================="
echo ""

# Check if icon file exists
if [ ! -f "assets/images/app_icon.png" ]; then
    echo "❌ Error: Icon file not found!"
    echo ""
    echo "Please save your app icon image to:"
    echo "   assets/images/app_icon.png"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Icon file found: assets/images/app_icon.png"
echo ""

# Check icon dimensions
if command -v sips &> /dev/null; then
    echo "📏 Checking icon dimensions..."
    WIDTH=$(sips -g pixelWidth assets/images/app_icon.png | tail -1 | awk '{print $2}')
    HEIGHT=$(sips -g pixelHeight assets/images/app_icon.png | tail -1 | awk '{print $2}')
    echo "   Icon size: ${WIDTH}x${HEIGHT} pixels"
    
    if [ "$WIDTH" -lt 512 ] || [ "$HEIGHT" -lt 512 ]; then
        echo "⚠️  Warning: Icon is smaller than recommended (1024x1024)"
        echo "   Your icon might appear blurry on some devices."
    else
        echo "✅ Icon size is good!"
    fi
    echo ""
fi

echo "🔨 Generating app icons..."
flutter pub run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ App icons generated successfully!"
    echo ""
    echo "📱 Next steps:"
    echo "   1. Clean previous builds: flutter clean"
    echo "   2. Build new APK: ./build_apk_java21.sh"
    echo ""
    echo "🎉 Your app will now show:"
    echo "   • Name: CatchUp"
    echo "   • Icon: Your custom design"
else
    echo ""
    echo "❌ Icon generation failed!"
    echo "   Check the error messages above."
    exit 1
fi

