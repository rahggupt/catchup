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

✅ **Authentication** - Email/Password, Google OAuth, default collections on signup
✅ **RSS Feed Integration** - Client-side fetching with CORS proxy
✅ **Swipe Feed** - TikTok-style single article view with CurateFlow UX
✅ **Collections** - Save and organize articles (3 default collections)
✅ **Profile Stats** - Real-time from Supabase DB
✅ **Source Management** - Add, disable, delete sources
✅ **AI Chat** - Google Gemini with RAG (Qdrant vectors)
✅ **Delete Functionality** - Collections & sources
✅ **Scrollable Content** - Article content fully scrollable
✅ **Smart Swipe Detection** - 20% threshold, velocity detection, dead zone

---

## 🧪 Testing

### Comprehensive API Test Suite

**47 tests** covering all external APIs and integrations.

```bash
# Run all tests
./run_tests.sh
```

**Test Coverage:**
- ✅ Supabase API (4 tests) - Connection, Auth, Database, Realtime
- ✅ Gemini API (2 tests) - Models, Content Generation
- ✅ Qdrant API (11 tests) - CRUD operations, Vector search
- ✅ Hugging Face (2 tests) - Embeddings, Models
- ✅ RSS Feeds (4 tests) - TechCrunch, Wired, Ars, CORS proxy
- ✅ Supabase CRUD (11 tests) - Full Create/Read/Update/Delete
- ✅ Integration (3 tests) - RAG pipeline, DB+Auth, RSS flow
- ✅ Error Handling (5 tests) - Invalid credentials, timeouts
- ✅ Performance (3 tests) - Response time benchmarks

**Latest Results:** ✅ 47 tests, 0 failures, ~13s execution

### Test Documentation
- `TEST_REPORT.md` - Comprehensive test report with 3 iterations
- `TEST_SUITE_README.md` - Full documentation & troubleshooting
- `TEST_SUITE_SUMMARY.md` - Quick reference guide
- `test/api_test_suite.dart` - Test implementation

### Performance Benchmarks
- **Gemini:** 288ms (target < 5s) ✅
- **Supabase:** 90ms (target < 2s) ✅
- **RSS Feeds:** ~500ms per feed ✅

---

## 🐛 Recent Bug Fixes (Latest)

### Swipe & Scroll Improvements
- ✅ **Scrollable Article Content** - Full content now scrollable, no truncation
- ✅ **20% Swipe Threshold** - Indicators only show after 20% screen drag
- ✅ **Velocity Detection** - Quick flicks trigger swipes even with short drag
- ✅ **30px Dead Zone** - Prevents accidental card movements
- ✅ **Scroll-Swipe Conflict Resolution** - No horizontal swipe during vertical scroll
- ✅ **Enhanced Visual Feedback** - Better rotation, opacity, scale, and shadows
- ✅ **Haptic Feedback** - Vibration on swipe actions and reset

### Collections & Database
- ✅ **Default Collections** - New users get 3 default collections automatically
  - "Saved Articles" - Articles saved for later reading
  - "Read Later" - Queue of articles to read
  - "Favorites" - Your favorite articles
- ✅ **Mock Collection Removal** - No more mock data blocking real collections
- ✅ **Add to Collection Fix** - Works with all real UUID collections
- ✅ **SQL Migration** - Script for existing users: `database/create_default_collections.sql`

### Test Suite
- ✅ **Gemini Model Fix** - Updated to use stable `gemini-pro` model
- ✅ **47 Tests Passing** - All API tests working correctly
- ✅ **CurateFlow Lint Fix** - React import added, 48 lint errors resolved

### Files Modified
- `lib/features/feed/presentation/widgets/scrollable_article_card.dart`
- `lib/features/feed/presentation/screens/swipe_feed_screen.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/collections/presentation/providers/collections_provider.dart`
- `lib/features/collections/presentation/widgets/add_to_collection_modal.dart`
- `test/api_test_suite.dart`
- `database/create_default_collections.sql` (NEW)
- `CurateFlow App Development/src/components/FeedTab.tsx`

---

## References

- **Supabase Dashboard:** https://qgvmyntagfukrodafzfc.supabase.co
- **Flutter Docs:** https://flutter.dev/docs
- **Android Setup:** `ANDROID_INSTALL.md`
- **Fix Guides:** `FIX_LOGIN_ERROR.md`, `FIX_ADD_TO_COLLECTION.md`
- **Test Report:** `TEST_REPORT.md`
- **DB Migration:** `database/create_default_collections.sql`
  