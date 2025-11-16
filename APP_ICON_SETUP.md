# CatchUp App Icon Setup Guide

## ✅ Configuration Complete!

The app has been renamed to **"CatchUp"** on both Android and iOS.

## 📱 Next Steps: Set Your App Icon

### Step 1: Save the Icon Image

1. **Right-click** on the app icon image you provided in the chat
2. **Save it** to: `/Users/rahulg/Catch Up/mindmap_aggregator/assets/images/app_icon.png`
3. Make sure the filename is exactly: `app_icon.png`

### Step 2: Generate App Icons

Once you've saved the image, run these commands:

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# Install dependencies (including flutter_launcher_icons)
flutter pub get

# Generate app icons for Android and iOS
flutter pub run flutter_launcher_icons
```

### Step 3: Rebuild the App

```bash
# Clean previous builds
flutter clean

# Build new APK with the icon and new name
./build_apk_java21.sh
```

## 🎨 What Was Changed

### ✅ App Name Updated
- **Android**: Changed from "mindmap_aggregator" to "CatchUp"
- **iOS**: Changed from "Mindmap Aggregator" to "CatchUp"

### ✅ Icon Configuration Added
- Added `flutter_launcher_icons` package to `pubspec.yaml`
- Configured adaptive icons for Android with orange background (#FF8A65)
- Configured app icons for both Android and iOS
- Created `assets/images/` directory for the icon

### ✅ Files Modified
1. `android/app/src/main/AndroidManifest.xml` - Updated app label
2. `ios/Runner/Info.plist` - Updated CFBundleDisplayName and CFBundleName
3. `pubspec.yaml` - Added flutter_launcher_icons and configuration

## 📂 Directory Structure

```
mindmap_aggregator/
├── assets/
│   └── images/
│       └── app_icon.png  ← Save your icon here
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml  ← Updated ✓
├── ios/
│   └── Runner/
│       └── Info.plist  ← Updated ✓
└── pubspec.yaml  ← Updated ✓
```

## 🎯 Icon Requirements

For best results, your icon image should be:
- **Format**: PNG with transparency
- **Size**: At least 1024x1024 pixels (recommended)
- **Content**: The icon design you provided shows two people chatting - perfect!

## 🔧 Troubleshooting

### If icon generation fails:
```bash
# Try cleaning first
flutter clean
rm -rf ios/Pods
flutter pub get
flutter pub run flutter_launcher_icons
```

### If you see caching issues:
```bash
# Clear Flutter cache
flutter clean
flutter pub cache repair
flutter pub get
```

## 📱 Verify the Changes

After rebuilding:
1. **App Name**: Should show as "CatchUp" on home screen
2. **App Icon**: Should show your custom icon (two people chatting on orange background)
3. **Inside App**: Icon will be available as an asset at `assets/images/app_icon.png`

---

**Ready to proceed?** Just save the icon image to the path above and run the commands! 🚀

