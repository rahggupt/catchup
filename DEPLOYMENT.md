# Deployment Guide

This guide covers deploying the Mindmap Aggregator app to the App Store (iOS) and Google Play Store (Android).

## Prerequisites

- Completed app development
- Apple Developer Account ($99/year) for iOS
- Google Play Developer Account ($25 one-time) for Android
- App testing completed
- Backend services configured (Supabase, Gemini, Qdrant)

## Pre-Deployment Checklist

### 1. App Configuration

- [ ] Update app name in `pubspec.yaml`
- [ ] Set correct version number (`version: 1.0.0+1`)
- [ ] Configure app icons
- [ ] Add splash screens
- [ ] Configure deep linking
- [ ] Set up proper environment variables

### 2. Code Quality

- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests passing
- [ ] Remove all debug prints
- [ ] Check for TODO comments
- [ ] Optimize images and assets

### 3. Legal & Privacy

- [ ] Create Privacy Policy
- [ ] Create Terms of Service
- [ ] Update app description
- [ ] Add required permissions documentation

## iOS Deployment

### 1. Configure Xcode Project

```bash
cd ios
open Runner.xcworkspace
```

In Xcode:
1. Select Runner project
2. General tab:
   - Set Display Name: "CatchUp"
   - Set Bundle Identifier: `com.catchup.mindmapaggregator`
   - Set Version: 1.0.0
   - Set Build: 1
3. Signing & Capabilities:
   - Select your development team
   - Enable automatic signing
4. Info tab:
   - Add privacy descriptions:
     - NSCameraUsageDescription
     - NSPhotoLibraryUsageDescription
     - NSMicrophoneUsageDescription (if using voice)

### 2. Create App Icons

Use [App Icon Generator](https://appicon.co/) to create all required sizes.

Place in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 3. Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app
3. Fill in app information:
   - Name: CatchUp
   - Primary Language: English
   - Bundle ID: com.catchup.mindmapaggregator
   - SKU: catchup-mindmap-1
4. Add screenshots (required sizes):
   - 6.5" display (iPhone 14 Pro Max): 1290 x 2796
   - 5.5" display (iPhone 8 Plus): 1242 x 2208
5. Write app description
6. Add keywords
7. Select category: Productivity
8. Set age rating

### 4. Build and Upload

```bash
# Clean build
flutter clean

# Build release IPA
flutter build ipa --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=QDRANT_URL=your_url \
  --dart-define=QDRANT_API_KEY=your_key \
  --dart-define=HUGGINGFACE_API_KEY=your_key

# Upload to App Store Connect
open build/ios/archive/Runner.xcarchive
```

In Xcode Organizer:
1. Select the archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Follow prompts to upload

### 5. Submit for Review

1. In App Store Connect, go to your app
2. Select the build
3. Fill in "What's New" section
4. Submit for review

**Review time**: Usually 24-48 hours

## Android Deployment

### 1. Configure App

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.catchup.mindmapaggregator"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 2. Create App Icons

Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)

Place in `android/app/src/main/res/`

### 3. Create Signing Key

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Save password securely!

Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. Build Release APK/AAB

```bash
# Build App Bundle (recommended)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=QDRANT_URL=your_url \
  --dart-define=QDRANT_API_KEY=your_key \
  --dart-define=HUGGINGFACE_API_KEY=your_key

# Or build APK
flutter build apk --release --split-per-abi
```

Output:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`

### 5. Create Play Store Listing

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - App name: CatchUp
   - Default language: English
   - App or game: App
   - Free or paid: Free
4. Store listing:
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots (required):
     - Phone: 16:9 or 9:16, at least 2 screenshots
     - Tablet: 16:9 or 9:16, at least 1 screenshot
   - Feature graphic: 1024 x 500
   - App icon: 512 x 512
5. Categorization:
   - Application type: App
   - Category: Productivity
   - Tags: News, Education, AI
6. Contact details
7. Privacy Policy URL

### 6. Upload and Publish

1. Go to "Release" > "Production"
2. Click "Create new release"
3. Upload AAB file
4. Fill in release notes
5. Review and rollout

**Review time**: Usually a few hours to 1 day

## Post-Deployment

### Monitoring

1. **Crashlytics**: Set up Firebase Crashlytics
2. **Analytics**: Add Google Analytics or Firebase Analytics
3. **Performance**: Monitor API response times
4. **User Feedback**: Monitor app store reviews

### Updates

To release an update:

1. Increment version in `pubspec.yaml`
   - Version name: `1.0.1`
   - Build number: `+2`
2. Make changes
3. Test thoroughly
4. Build and upload
5. Submit for review

## Environment Variables for Production

Create a shell script for easy deployment:

`scripts/build_release.sh`:

```bash
#!/bin/bash

# Load production environment
source .env.production

# Build iOS
flutter build ipa --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=QDRANT_URL=$QDRANT_URL \
  --dart-define=QDRANT_API_KEY=$QDRANT_API_KEY \
  --dart-define=HUGGINGFACE_API_KEY=$HUGGINGFACE_API_KEY

# Build Android
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=QDRANT_URL=$QDRANT_URL \
  --dart-define=QDRANT_API_KEY=$QDRANT_API_KEY \
  --dart-define=HUGGINGFACE_API_KEY=$HUGGINGFACE_API_KEY

echo "Build complete!"
echo "iOS: build/ios/archive/Runner.xcarchive"
echo "Android: build/app/outputs/bundle/release/app-release.aab"
```

## Cost Optimization

Since using free tiers:

1. **Monitor Usage**: Check Supabase, Gemini, Qdrant dashboards
2. **Implement Caching**: Reduce API calls
3. **Optimize Embeddings**: Batch process when possible
4. **Rate Limiting**: Implement user-side rate limits

## Troubleshooting

### iOS Build Fails

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios
```

### Android Build Fails

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

### App Rejected

Common reasons:
- Missing privacy policy
- Incomplete app information
- Crashes during review
- Guideline violations

Fix issues and resubmit.

## Marketing

1. **App Store Optimization (ASO)**
   - Keywords in title and description
   - Quality screenshots
   - Positive reviews

2. **Launch Strategy**
   - Beta testing (TestFlight/Play Beta)
   - Soft launch in select countries
   - Gather feedback
   - Full launch

3. **Promotion**
   - Social media
   - Product Hunt launch
   - Blog posts
   - Press releases

## Success Metrics

Track:
- Downloads
- Daily/Monthly Active Users
- Retention rate
- Crash-free rate (aim for >99%)
- Average rating (aim for >4.0)
- User reviews

## Support

- Create support email: support@catchup.app
- FAQ page
- In-app help
- Community forum or Discord

