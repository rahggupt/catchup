# 🚀 Quick Start: Release to Play Store

Follow these steps in order to publish your app to Google Play Store.

---

## Step 1: Create Release Keystore (5 minutes)

This is your app's digital signature. **Keep it safe!**

```bash
# Create keystores directory
mkdir -p ~/keystores
cd ~/keystores

# Generate keystore (you'll be prompted for passwords and details)
keytool -genkey -v -keystore catchup-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias catchup-key
```

**Important prompts:**
- **Keystore password**: Choose a strong password (e.g., `CatchUp@2025SecureKey`)
- **Key password**: Can be the same as keystore password
- **Name**: Your name
- **Organization**: Your company or "Independent"
- **City, State, Country**: Your location

**Write down your passwords!** You'll need them for every release.

---

## Step 2: Configure Signing (2 minutes)

Create `android/key.properties` file:

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
cat > android/key.properties << 'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=catchup-key
storeFile=/Users/rahulg/keystores/catchup-release-key.jks
EOF
```

Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with your actual passwords.

**Security**: This file is already in `.gitignore` - never commit it!

---

## Step 3: Get SHA-256 Fingerprint (1 minute)

You need this for Airbridge deep linking:

```bash
keytool -list -v \
  -keystore ~/keystores/catchup-release-key.jks \
  -alias catchup-key | grep SHA256
```

**Copy the output** (looks like `XX:XX:XX:...`). You'll add this to:
1. Airbridge Dashboard → Settings → Deep Links → Android App Links
2. Google Play Console (optional, for App Signing)

---

## Step 4: Build Release App Bundle (5 minutes)

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# Clean and get dependencies
flutter clean
flutter pub get

# Build the release AAB for Play Store
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

**Verify it was created:**
```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

Should show a file around 20-30MB.

---

## Step 5: Test Release Build (Optional but Recommended)

Build and install a release APK to test:

```bash
# Build release APK
flutter build apk --release

# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Test deep linking
adb shell am start -a android.intent.action.VIEW \
  -d "https://catchup.airbridge.io/c/eq2sgv000000"
```

**Test checklist:**
- [ ] App opens without crashes
- [ ] Login works
- [ ] Feed loads articles
- [ ] Collections work
- [ ] AI chat works
- [ ] Deep links work
- [ ] Share functionality works

---

## Step 6: Create Google Play Console Account (15 minutes)

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google Account
3. Pay $25 one-time registration fee
4. Complete developer profile

---

## Step 7: Create App in Play Console (10 minutes)

1. Click **"Create app"**
2. Fill in:
   - **App name**: Catch Up
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Click **Create app**

---

## Step 8: Complete App Content (30 minutes)

In Play Console → Your App, complete these sections:

### 8.1 Privacy Policy

**You MUST have a privacy policy URL.** Quick option:

1. Create a GitHub Gist or use Google Sites
2. Write a simple privacy policy (see template in main guide)
3. Add the URL in Play Console → App content → Privacy policy

### 8.2 App Access

- Select: "All functionality is available without special access"
- Or provide test login credentials for reviewers

### 8.3 Ads

- Select: "No, my app does not contain ads"

### 8.4 Content Ratings

1. Click **Start questionnaire**
2. Answer questions about your app
3. Submit for rating

### 8.5 Target Audience

- Select age ranges: 13+
- Select: No, my app is not primarily for children

### 8.6 Data Safety

Declare what data you collect:
- [ ] Email address
- [ ] User-generated content (articles, collections)
- [ ] App activity (usage analytics via Airbridge)

---

## Step 9: Create Store Listing (1 hour)

In Play Console → Main store listing:

### 9.1 Text

- **App name**: Catch Up
- **Short description** (80 chars):
  ```
  Personalized news feed with AI insights and smart article organization
  ```
- **Full description**: See template in main guide

### 9.2 Graphics

**Required:**

1. **App Icon** (512x512 PNG)
   - Your launcher icon at high resolution
   - No transparency, no padding

2. **Feature Graphic** (1024x500 PNG)
   - Create a banner with app name and key visual

3. **Screenshots** (at least 2)
   - Take from your phone or emulator
   - Show main screens: Feed, Collections, AI Chat

**Create screenshots:**
```bash
# Take screenshots via ADB
adb exec-out screencap -p > screenshot1.png
```

Or use your phone's screen capture feature.

### 9.3 Categorization

- **App category**: News & Magazines
- **Tags**: news, rss, ai, collections

### 9.4 Contact Details

- **Email**: Your support email
- **Website**: Optional (can be GitHub repo)

---

## Step 10: Upload AAB and Release (15 minutes)

1. Go to Play Console → Your App → **Production**
2. Click **Create new release**
3. Click **Upload** and select: `app-release.aab`
4. Wait for Google to process (~5-10 minutes)
5. Add **Release notes**:
   ```
   Version 1.0.0 - Initial Release
   
   Welcome to Catch Up! 
   
   • Personalized news feed
   • Smart collections
   • AI-powered insights
   • Share collections with friends
   ```
6. Click **Review release**
7. Fix any warnings
8. Click **Start rollout to Production**

---

## Step 11: Wait for Review (1-7 days)

Google will review your app. You'll receive email notifications.

**During review:**
- Check Play Console for status
- Respond to any requests from Google
- Don't change the app

---

## Step 12: Post-Launch

Once approved:

1. **Add release SHA-256 to Airbridge**
   - Copy the SHA-256 from Step 3
   - Go to Airbridge Dashboard → Settings → Deep Links
   - Add the fingerprint

2. **Test production app**
   - Download from Play Store
   - Test all features
   - Test deep links

3. **Monitor**
   - Check Play Console for crash reports
   - Respond to user reviews
   - Track analytics in Airbridge

---

## 🔄 For Future Updates

When you want to release an update:

### 1. Update version

Edit `android/app/build.gradle.kts`:
```kotlin
versionCode = 2       // Increment by 1
versionName = "1.0.1" // Update version string
```

### 2. Build new AAB

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### 3. Upload to Play Console

1. Go to Production → Create new release
2. Upload new AAB
3. Add release notes describing what's new
4. Roll out

---

## 📋 Complete Checklist

**Before Building:**
- [ ] Keystore created and backed up
- [ ] `key.properties` file created
- [ ] Package name changed to `com.catchup.app`
- [ ] Version code and name set
- [ ] All features tested

**Play Console:**
- [ ] Account created ($25 paid)
- [ ] App created
- [ ] Privacy policy URL added
- [ ] Content rating completed
- [ ] Data safety completed
- [ ] Store listing filled out
- [ ] App icon uploaded (512x512)
- [ ] Feature graphic uploaded (1024x500)
- [ ] Screenshots uploaded (at least 2)

**Release:**
- [ ] AAB built successfully
- [ ] Release APK tested locally
- [ ] AAB uploaded to Play Console
- [ ] Release notes added
- [ ] Released to production

**Post-Launch:**
- [ ] Release SHA-256 added to Airbridge
- [ ] App downloaded and tested from Play Store
- [ ] Monitoring set up

---

## ⚠️ Important Reminders

1. **Keystore**: Back it up! Without it, you can't update your app
2. **key.properties**: Never commit to git
3. **Version code**: Must increase for each release
4. **Privacy policy**: Required by Google, must be publicly accessible
5. **SHA-256**: Add release fingerprint to Airbridge for deep links

---

## 🆘 Common Issues

### "Upload failed: You need to use a different package name"

Package name `com.example.*` is not allowed. Change to `com.catchup.app` in:
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`

### "App not signed"

Make sure `key.properties` file exists and has correct paths/passwords.

### "SHA1 fingerprint mismatch"

Add your **release** keystore SHA-256 to Airbridge, not debug.

### "Privacy policy required"

Create a simple privacy policy page and add the URL in Play Console.

---

## 📞 Need Help?

- **Play Console**: https://support.google.com/googleplay/android-developer
- **Flutter Docs**: https://docs.flutter.dev/deployment/android
- **Full Guide**: See `PLAY_STORE_DEPLOYMENT_GUIDE.md`

---

**Estimated Total Time**: 3-4 hours (excluding Google review)

Good luck with your launch! 🎉

