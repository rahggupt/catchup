# 📱 Build Script Usage Guide

## Overview

The `build_apk_java21.sh` script now supports building both **production** and **debug** APKs with a simple parameter.

---

## 🚀 Usage

### Production Build (No Debug Logs)

```bash
./build_apk_java21.sh
```

**Result:**
- ✅ APK: `app-release.apk`
- ✅ Debug section **hidden** from users
- ✅ Optimized for end users
- ✅ Smaller APK size

---

### Debug Build (With Debug Logs)

```bash
./build_apk_java21.sh --debug
```

**Result:**
- ✅ APK: `app-release-debug.apk`
- ✅ Debug section **visible** in Profile > Debug Settings
- ✅ All logs and errors captured
- ✅ Download and share logs feature enabled
- ⚠️ Slightly larger APK size

---

### Show Help

```bash
./build_apk_java21.sh --help
```

---

## 📂 Output

### Production Build Output:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Debug Build Output:
```
build/app/outputs/flutter-apk/app-release-debug.apk
```

The APK is automatically renamed based on the build mode!

---

## 📱 Installing the APK

### Method 1: Via USB (Phone Connected)

```bash
# Production
adb install build/app/outputs/flutter-apk/app-release.apk

# Debug
adb install build/app/outputs/flutter-apk/app-release-debug.apk
```

### Method 2: Transfer to Phone

1. Find the APK in `build/app/outputs/flutter-apk/`
2. Transfer to your phone (email, AirDrop, Google Drive, etc.)
3. On phone: tap the APK to install
4. Enable 'Install from Unknown Sources' if prompted

### Method 3: Open in Finder

The script automatically opens Finder with the APK location after successful build.

---

## 🐛 Debug Mode Features

When you build with `--debug`, the app includes:

### In the App:
- ✅ **Debug Settings** section in Profile (with red "DEV" badge)
- ✅ **View Debug Logs** screen with:
  - Log summary (Info, Warning, Error, Debug counts)
  - Filter by level and category
  - Expandable log entries with full details
  - Copy individual logs
- ✅ **Download Logs** as txt file to phone storage
- ✅ **Share Logs** via email/messaging

### What Gets Logged:
- Auth events (login, signup, errors)
- Collection operations (create, update, delete)
- Feed loading and errors
- AI chat interactions
- Database operations
- API calls and responses
- Network errors
- All exceptions with stack traces

---

## 📋 Complete Workflow

### For Development/Testing:

```bash
# 1. Build debug version
./build_apk_java21.sh --debug

# 2. Install on phone
adb install build/app/outputs/flutter-apk/app-release-debug.apk

# 3. Use the app and reproduce issues
# 4. Go to Profile > Debug Settings > View Debug Logs
# 5. Download or share the logs
```

### For Production Release:

```bash
# 1. Build production version
./build_apk_java21.sh

# 2. Install on phone
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. Debug section won't appear
# 4. Users won't see any debug features
```

---

## 🔍 Differences Between Builds

| Feature | Production | Debug |
|---------|-----------|-------|
| **APK Name** | app-release.apk | app-release-debug.apk |
| **Debug Section** | ❌ Hidden | ✅ Visible |
| **Log Capture** | ❌ Disabled | ✅ Enabled |
| **Download Logs** | ❌ Not available | ✅ Available |
| **APK Size** | Smaller | Slightly larger |
| **Performance** | Optimized | Minimal overhead |
| **Use Case** | End users | Testing/debugging |

---

## 💡 When to Use Each

### Use Production Build When:
- ✅ Releasing to users
- ✅ Distributing via Google Play
- ✅ Sharing with non-technical users
- ✅ Final release candidate

### Use Debug Build When:
- ✅ Testing new features
- ✅ Debugging issues
- ✅ Need to capture logs
- ✅ QA testing
- ✅ Troubleshooting production issues

---

## ⚙️ Environment Variables

The script reads these from `.env` file:

```bash
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
GEMINI_API_KEY=your_gemini_key
QDRANT_URL=your_qdrant_url
QDRANT_API_KEY=your_qdrant_key
HUGGINGFACE_API_KEY=your_hf_key
```

Both production and debug builds use the same `.env` file.

---

## 🛠️ Troubleshooting

### Script Not Executable

```bash
chmod +x build_apk_java21.sh
```

### .env File Not Found

```bash
# Copy example and fill in values
cp .env.example .env
nano .env
```

### Java 21 Not Found

Update the script with your Java 21 path:

```bash
export JAVA_HOME="/your/path/to/openjdk@21"
```

### Debug Section Not Showing

Make sure you used `--debug` flag:

```bash
./build_apk_java21.sh --debug
```

Check in app: Profile → Should see "Debug Settings" with red "DEV" badge

---

## 📊 Build Time

Both builds take approximately:
- **First build:** 5-10 minutes
- **Subsequent builds:** 2-3 minutes

Debug mode adds ~5-10 seconds due to additional flag processing.

---

## 🎯 Quick Reference

```bash
# Production (no debug)
./build_apk_java21.sh

# Debug (with logs)
./build_apk_java21.sh --debug

# Show help
./build_apk_java21.sh --help

# Install production
adb install build/app/outputs/flutter-apk/app-release.apk

# Install debug
adb install build/app/outputs/flutter-apk/app-release-debug.apk
```

---

## 📝 Notes

1. The debug flag is **compile-time only** - you cannot enable debug mode in a production build
2. Both builds are **release mode** (optimized), the difference is only the DEBUG_MODE flag
3. Debug builds are **safe for testing** but not recommended for public distribution
4. The APK filename automatically reflects the build mode for easy identification

---

That's it! Happy building! 🚀

