# Install CatchUp on Android

## Prerequisites

1. **Flutter SDK** - Already installed ✅
2. **Android Studio** or **Android SDK Command Line Tools**
3. **Android Device or Emulator**

## Option 1: Using Physical Android Device (Recommended)

### Step 1: Enable Developer Mode on Your Phone

1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times to enable Developer Mode
3. Go back to **Settings** → **Developer Options**
4. Enable **USB Debugging**

### Step 2: Connect Your Phone to Computer

1. Connect your Android phone via USB cable
2. On your phone, allow USB debugging when prompted
3. Verify connection:
   ```bash
   cd "/Users/rahulg/Catch Up/mindmap_aggregator"
   flutter devices
   ```
   You should see your phone listed.

### Step 3: Run the App

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
./run_with_env.sh
```

When prompted, select your Android device.

## Option 2: Using Android Emulator

### Step 1: Install Android Studio

1. Download from: https://developer.android.com/studio
2. During installation, make sure to install:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)

### Step 2: Create an Emulator

1. Open Android Studio
2. Click **More Actions** → **Virtual Device Manager**
3. Click **Create Device**
4. Select a device (e.g., Pixel 6)
5. Download a system image (e.g., Android 13)
6. Finish creating the emulator

### Step 3: Start Emulator and Run App

```bash
# List available emulators
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
flutter emulators

# Launch an emulator (replace with your emulator ID)
flutter emulators --launch <emulator_id>

# Run the app
./run_with_env.sh
```

## Option 3: Build APK to Install Manually

### Build Release APK

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# Build APK with environment variables
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_URL="$QDRANT_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY"
```

The APK will be created at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Install APK on Your Phone

**Method 1: Via USB**
```bash
# Install to connected device
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: Transfer and Install**
1. Copy `app-release.apk` to your phone (email, Google Drive, etc.)
2. On your phone, locate the APK file
3. Tap to install (may need to allow "Install from Unknown Sources")

## Quick Script for Android with Env Variables

Create `run_android.sh`:
```bash
#!/bin/bash

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Run on Android
flutter run -d android \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=QDRANT_URL="$QDRANT_URL" \
  --dart-define=QDRANT_API_KEY="$QDRANT_API_KEY" \
  --dart-define=HUGGINGFACE_API_KEY="$HUGGINGFACE_API_KEY"
```

Then run:
```bash
chmod +x run_android.sh
./run_android.sh
```

## Troubleshooting

### Error: "No devices found"
```bash
# Check if device is connected
adb devices

# If no devices, try:
adb kill-server
adb start-server
```

### Error: "Unable to locate Android SDK"
Add to your `~/.zshrc` or `~/.bash_profile`:
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### App crashes on startup
Make sure you're using the script that passes environment variables:
```bash
./run_android.sh  # NOT just "flutter run"
```

## Notes

- First build may take 5-10 minutes
- Debug APKs are larger (~40-50MB), Release APKs are smaller (~15-20MB)
- Make sure your phone has "Install from Unknown Sources" enabled if installing APK manually

