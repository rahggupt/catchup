# 📱 Google Play Store Deployment Guide

Complete step-by-step guide to publish your Catch Up app on Google Play Store.

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Google Account
- [ ] $25 USD for one-time Google Play Console registration fee
- [ ] App fully tested and working
- [ ] Privacy Policy URL (required by Google)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (at least 2, recommended 4-8)
- [ ] App description and details ready

---

## Part 1: Google Play Console Setup

### Step 1: Create Google Play Console Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google Account
3. Accept the Developer Distribution Agreement
4. Pay the one-time $25 registration fee
5. Complete your account details

**Time Required**: 10-15 minutes

---

### Step 2: Create Your App

1. In Play Console, click **"Create app"**
2. Fill in the required information:
   - **App name**: Catch Up
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Accept declarations and click **Create app**

---

## Part 2: Generate Release Keystore (Signing Key)

### Step 1: Create Keystore

This is your app's digital signature. **KEEP IT SAFE** - you'll need it for all future updates!

```bash
cd ~/
mkdir keystores
cd keystores

keytool -genkey -v -keystore catchup-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias catchup-key
```

**You'll be asked for:**
- Keystore password (choose a strong password, write it down!)
- Key password (can be same as keystore password)
- Your name
- Organization unit
- Organization name
- City
- State
- Country code (e.g., US)

**IMPORTANT**: 
- Store this keystore file safely (backup to cloud storage)
- Never commit it to git
- Never share it publicly
- You cannot update your app without it!

### Step 2: Get SHA-256 Fingerprint

You'll need this for Airbridge and other services:

```bash
keytool -list -v -keystore ~/keystores/catchup-release-key.jks \
  -alias catchup-key | grep SHA256
```

Save this SHA-256 fingerprint - you'll add it to:
1. Airbridge Dashboard (for deep linking)
2. Google Play Console (for App Signing)

---

## Part 3: Configure App for Release

### Step 1: Update Android Configuration

**File**: `android/key.properties` (create this file)

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=catchup-key
storeFile=/Users/YOUR_USERNAME/keystores/catchup-release-key.jks
```

**IMPORTANT**: Add `key.properties` to `.gitignore`:

```bash
echo "android/key.properties" >> .gitignore
```

### Step 2: Update build.gradle.kts

**File**: `android/app/build.gradle.kts`

Add this BEFORE the `android {` block:

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    // Add signing configs
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // ProGuard rules for optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

### Step 3: Update App Details

**File**: `android/app/src/main/AndroidManifest.xml`

Update these values:

```xml
<manifest>
    <application
        android:label="Catch Up"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of config ... -->
    </application>
</manifest>
```

**File**: `android/app/build.gradle.kts`

Update version information:

```kotlin
defaultConfig {
    applicationId = "com.catchup.mindmap_aggregator"  // Change from com.example
    minSdk = 21
    targetSdk = 34
    versionCode = 1      // Increment for each release
    versionName = "1.0.0" // User-visible version
}
```

### Step 4: Update Package Name (Important!)

Change from `com.example.mindmap_aggregator` to your own package name:

1. **Update `build.gradle.kts`**:
   ```kotlin
   applicationId = "com.catchup.app"
   ```

2. **Update `AndroidManifest.xml`**:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android"
       package="com.catchup.app">
   ```

3. **Rename package directories**:
   ```bash
   cd android/app/src/main/kotlin
   mkdir -p com/catchup/app
   mv com/example/mindmap_aggregator/MainActivity.kt com/catchup/app/
   rm -rf com/example
   ```

4. **Update MainActivity.kt**:
   ```kotlin
   package com.catchup.app
   
   import io.flutter.embedding.android.FlutterActivity
   
   class MainActivity: FlutterActivity() {
   }
   ```

---

## Part 4: Build Release App Bundle (AAB)

Google Play requires AAB (Android App Bundle) format, not APK.

### Build the AAB

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# Clean previous builds
flutter clean
flutter pub get

# Build release AAB
flutter build appbundle --release
```

**Output location**: `build/app/outputs/bundle/release/app-release.aab`

**Expected size**: ~20-30MB (much smaller than APK)

### Verify the Build

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

Should show the AAB file with size.

---

## Part 5: Play Store Listing

### Step 1: App Content

In Play Console → Your App → **App content**, complete:

1. **Privacy Policy**
   - Required by Google
   - Must be hosted on a public URL
   - Example: Create a page on GitHub Pages or use Google Sites
   - Include:
     - What data you collect (user email, articles saved, etc.)
     - How you use the data
     - Third-party services (Supabase, Airbridge, Perplexity)
     - User rights (delete account, export data)

2. **App Access**
   - Provide login credentials for Google reviewers to test
   - Or mark as "All functionality is available without special access"

3. **Ads**
   - Select "No, my app does not contain ads"

4. **Content Ratings**
   - Complete the questionnaire
   - Select appropriate age ratings

5. **Target Audience**
   - Select age groups (likely 13+)

6. **Data Safety**
   - Declare what data you collect
   - Select: Account creation, User-generated content, etc.

### Step 2: Store Listing

In Play Console → Your App → **Main store listing**:

1. **App Name**: Catch Up

2. **Short Description** (80 characters max):
   ```
   Your personalized news feed with AI-powered insights and article collections
   ```

3. **Full Description** (4000 characters max):
   ```
   Catch Up - Stay Informed, Stay Organized
   
   Catch Up is your intelligent news companion that helps you discover, organize, 
   and understand the news that matters to you.
   
   KEY FEATURES:
   
   📰 Personalized Feed
   • Swipe through articles from your favorite sources
   • TechCrunch, Wired, and custom RSS feeds
   • Smart filtering to show what you care about
   
   📚 Collections
   • Organize articles into custom collections
   • Share collections with friends via deep links
   • Private, invite-only, or public sharing options
   
   🤖 AI-Powered Insights
   • Ask questions about your saved articles
   • Get summaries and insights powered by AI
   • Context-aware responses from your collection
   
   🎯 Smart Features
   • Swipe left to reject, right to save
   • Vertical scrolling between articles
   • Offline reading support
   • Dark mode ready
   
   Perfect for:
   • News enthusiasts who want better organization
   • Professionals tracking industry news
   • Students researching topics
   • Anyone wanting curated, intelligent news consumption
   
   Privacy First:
   • Your data stays yours
   • No ads, no tracking
   • Secure authentication
   
   Download Catch Up today and transform how you read the news!
   ```

4. **App Icon** (512x512 PNG):
   - Upload your app icon
   - No transparency, no padding
   - Must be exactly 512x512 pixels

5. **Feature Graphic** (1024x500 PNG):
   - Create a banner showcasing your app
   - Include app name and key features

6. **Screenshots** (Minimum 2, Maximum 8):
   - Take screenshots from your phone:
     - Feed screen with articles
     - Collections screen
     - AI chat screen
     - Profile screen
   - Use `adb` or screen capture on phone
   - Remove status bar if desired

7. **Categorization**:
   - App category: News & Magazines
   - Tags: news, RSS, AI, productivity

### Step 3: Contact Details

- Email: Your support email
- Phone: Optional
- Website: Optional (or GitHub repo URL)

---

## Part 6: Upload and Release

### Step 1: Create Release

1. In Play Console → Your App → **Production**
2. Click **Create new release**
3. Upload your AAB: `app-release.aab`
4. Google Play will analyze your app (~5-10 minutes)

### Step 2: Release Notes

Write what's new in this version:

```
Version 1.0.0 - Initial Release

Welcome to Catch Up! 🎉

Features:
• Personalized news feed from TechCrunch, Wired, and custom sources
• Smart collections to organize your articles
• AI-powered chat to get insights from your saved articles
• Share collections with friends via shareable links
• Swipe interface for quick article management
• Dark mode support

We're excited to help you stay informed!

Feedback? Email us at support@catchup.app
```

### Step 3: Review and Rollout

1. Review all sections for completeness
2. Click **Review release**
3. Fix any warnings or errors
4. Click **Start rollout to Production**

**Google Review Process**:
- Usually takes 1-7 days
- You'll get email notifications
- Check Play Console for status

---

## Part 7: Post-Launch Checklist

### After Approval

- [ ] Update Airbridge with **release** SHA-256 fingerprint
- [ ] Test download from Play Store
- [ ] Test deep links work in production
- [ ] Set up Play Store monitoring in Play Console
- [ ] Monitor crash reports
- [ ] Respond to user reviews

### Future Updates

When releasing updates:

1. Increment version numbers in `build.gradle.kts`:
   ```kotlin
   versionCode = 2       // Always increment by 1
   versionName = "1.0.1" // Follow semantic versioning
   ```

2. Build new AAB:
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Console → Production → Create new release

---

## Part 8: Common Issues & Solutions

### Issue 1: "Upload failed: Version code already used"

**Solution**: Increment `versionCode` in `build.gradle.kts`

### Issue 2: "Missing SHA-256 fingerprint"

**Solution**: Add release keystore fingerprint to Airbridge Dashboard

### Issue 3: "App not verified for deep links"

**Solution**: 
1. Add SHA-256 to Airbridge
2. Wait 24-48 hours for Google verification
3. Test with `adb shell am start -a android.intent.action.VIEW -d "https://catchup.airbridge.io/c/test"`

### Issue 4: "Privacy Policy required"

**Solution**: Create a simple privacy policy page. Template:

```markdown
# Privacy Policy for Catch Up

Last updated: [Date]

## Information We Collect
- Email address (for account creation)
- Article preferences and saved collections
- Usage analytics via Airbridge

## How We Use Your Information
- To provide personalized news feed
- To enable AI-powered features
- To improve app experience

## Third-Party Services
- Supabase (database hosting)
- Airbridge (analytics)
- Perplexity AI (AI features)

## Your Rights
- Delete your account at any time
- Export your data
- Opt-out of analytics

## Contact
Email: support@catchup.app
```

---

## 📊 Pre-Launch Checklist

Before submitting to Play Store:

**App Quality**:
- [ ] App tested on multiple devices
- [ ] No crashes or critical bugs
- [ ] All features working
- [ ] Deep links tested
- [ ] Performance optimized

**Play Store Requirements**:
- [ ] Release AAB built and signed
- [ ] Package name changed from com.example
- [ ] Version code and name set
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] At least 2 screenshots
- [ ] Privacy policy URL
- [ ] Store listing completed
- [ ] Content rating completed
- [ ] Target audience selected

**Airbridge**:
- [ ] Release SHA-256 added to dashboard
- [ ] Deep link domain verified
- [ ] App links configured

**Testing**:
- [ ] Signed APK tested locally
- [ ] Deep links work with release build
- [ ] All user flows tested

---

## 🚀 Quick Commands Reference

```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/keystores/catchup-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias catchup-key

# Get SHA-256 fingerprint
keytool -list -v -keystore ~/keystores/catchup-release-key.jks \
  -alias catchup-key | grep SHA256

# Build release AAB
flutter clean
flutter pub get
flutter build appbundle --release

# Build release APK (for testing)
flutter build apk --release

# Install release APK for testing
adb install build/app/outputs/flutter-apk/app-release.apk

# Test deep link
adb shell am start -a android.intent.action.VIEW \
  -d "https://catchup.airbridge.io/c/test-token"
```

---

## 📞 Support Resources

- **Play Console Help**: https://support.google.com/googleplay/android-developer
- **Flutter Release Docs**: https://docs.flutter.dev/deployment/android
- **Airbridge Support**: https://help.airbridge.io
- **App Signing**: https://developer.android.com/studio/publish/app-signing

---

## 🎯 Timeline

| Step | Time Required |
|------|---------------|
| Create Play Console account | 15 minutes |
| Generate keystore | 5 minutes |
| Configure app for release | 30 minutes |
| Build AAB | 5-10 minutes |
| Create store listing | 1-2 hours |
| Upload and submit | 30 minutes |
| Google review | 1-7 days |
| **Total (excluding review)** | **3-4 hours** |

---

**Good luck with your launch! 🚀**

Questions? Check the troubleshooting section or refer to official documentation.

