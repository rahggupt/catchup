# CatchUp - Development Notes

## Quick Start

### Run on Web (Chrome)
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
./run_with_env.sh
```

### Run on Android
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
./run_android.sh
```

---

## Building Android APK

### Prerequisites
- **Java 21 LTS** is required (already installed)
- First build takes 5-10 minutes (downloads Android SDK)

### Build Release APK
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
./build_apk_java21.sh
```

✅ **This script automatically:**
- Uses Java 21 (compatible with Gradle)
- Loads environment variables from `.env`
- Builds signed release APK
- Shows install instructions

### APK Output Location
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Installing APK on Phone

### Method 1: Via USB (Recommended)

**Setup Phone (One-time):**
1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times (enables Developer Mode)
3. Go to **Settings** → **Developer Options**
4. Enable **USB Debugging**

**Install:**
```bash
# Connect phone via USB cable
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Transfer APK to Phone

**Transfer:**
```bash
# Open APK folder in Finder
open build/app/outputs/flutter-apk/
```

Then:
1. Transfer `app-release.apk` to your phone (email, AirDrop, Google Drive)
2. On phone: tap the APK file
3. Tap **Install**
4. Enable **"Install from Unknown Sources"** if prompted

---

## Troubleshooting

### APK Build Fails

**Error: "Unsupported class file major version 68"**

✅ **Fixed:** Use `./build_apk_java21.sh` instead of `./build_apk.sh`

The new script uses Java 21 which is compatible with Gradle.

**Check Java version:**
```bash
java --version
# Should show: openjdk 21.x.x
```

### Login Issues (400 Bad Request)

**Most Common:** Email not confirmed

**Fix Option 1 - Disable Confirmations (Easiest for testing):**
1. Go to Supabase: https://qgvmyntagfukrodafzfc.supabase.co
2. **Authentication** → **Providers** → **Email**
3. **Uncheck** "Enable email confirmations"
4. **Save**
5. Create new account or try login again

**Fix Option 2 - Manually Confirm Email:**

In Supabase **SQL Editor**:
```sql
-- Check if email exists
SELECT email, email_confirmed_at 
FROM auth.users 
WHERE email = 'your-email@example.com';

-- Confirm email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'your-email@example.com';
```

### Add to Collection Not Working

**Run this SQL in Supabase SQL Editor:**
```sql
ALTER TABLE collection_articles
DROP CONSTRAINT IF EXISTS collection_articles_article_id_fkey;

ALTER TABLE collection_articles
ADD CONSTRAINT collection_articles_article_id_fkey
FOREIGN KEY (article_id)
REFERENCES articles(id)
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;
```

---

## Useful Commands

### Flutter
```bash
# Check environment
flutter doctor -v

# Clean build
flutter clean
flutter pub get

# List connected devices
flutter devices
```

### Android Debug
```bash
# List connected devices
adb devices

# View logs
adb logcat

# Install APK
adb install path/to/app.apk

# Uninstall app
adb uninstall com.example.mindmap_aggregator
```

### Java
```bash
# Check version
java --version

# Switch to Java 21 (for this terminal session)
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

---

## Environment Variables

All sensitive credentials are in `.env` file (not committed to git).

**Current Setup:**
- ✅ Supabase URL
- ✅ Supabase Anon Key
- ✅ Gemini API Key
- ✅ Qdrant URL & API Key
- ✅ Hugging Face API Key

**Scripts automatically load these variables:**
- `run_with_env.sh` - Web
- `run_android.sh` - Android device
- `build_apk_java21.sh` - Build APK

---

## Project Structure

```
mindmap_aggregator/
├── lib/
│   ├── features/        # Feature modules
│   │   ├── auth/       # Authentication
│   │   ├── feed/       # RSS feed & articles
│   │   ├── collections/# Collections management
│   │   ├── profile/    # User profile
│   │   └── ai/         # AI chat
│   ├── shared/         # Shared code
│   │   ├── models/     # Data models
│   │   ├── services/   # Services (Supabase, RSS, etc.)
│   │   └── widgets/    # Reusable widgets
│   └── core/           # Core config
├── android/            # Android native code
├── web/               # Web assets
├── .env               # Environment variables (SECRET)
├── run_with_env.sh    # Run on Chrome
├── run_android.sh     # Run on Android
└── build_apk_java21.sh # Build APK (uses Java 21)
```

---

## Key Features Implemented

✅ **Authentication** - Email/Password, Google OAuth
✅ **RSS Feed Integration** - Client-side fetching with CORS proxy
✅ **Swipe Feed** - TikTok-style single article view
✅ **Collections** - Save and organize articles
✅ **Profile Stats** - Real-time from Supabase DB
✅ **Source Management** - Add, disable, delete sources
✅ **AI Chat** - Google Gemini with RAG (Qdrant vectors)
✅ **Delete Functionality** - Collections & sources

---

## References

- **Supabase Dashboard:** https://qgvmyntagfukrodafzfc.supabase.co
- **Flutter Docs:** https://flutter.dev/docs
- **Android Setup:** `ANDROID_INSTALL.md`
- **Fix Guides:** `FIX_LOGIN_ERROR.md`, `FIX_ADD_TO_COLLECTION.md`
  