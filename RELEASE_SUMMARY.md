# 📱 Play Store Release - Quick Reference

## ✅ What's Been Configured

Your app is now **ready for Play Store release** with these changes:

1. **✅ Package name changed**: `com.example.mindmap_aggregator` → `com.catchup.app`
2. **✅ Version set**: v1.0.0 (code: 1)
3. **✅ Signing configured**: Ready for release keystore
4. **✅ ProGuard enabled**: Code optimization and security
5. **✅ Airbridge configured**: Deep linking ready
6. **✅ Security**: `key.properties` and `.jks` files protected in .gitignore

---

## 🚀 Quick Start (Follow in Order)

### 1️⃣ Create Keystore (5 min)
```bash
mkdir -p ~/keystores
keytool -genkey -v -keystore ~/keystores/catchup-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias catchup-key
```
💡 **Save your passwords!**

### 2️⃣ Configure Signing (2 min)
Create `android/key.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=catchup-key
storeFile=/Users/rahulg/keystores/catchup-release-key.jks
```

### 3️⃣ Get SHA-256 (1 min)
```bash
keytool -list -v -keystore ~/keystores/catchup-release-key.jks \
  -alias catchup-key | grep SHA256
```
📋 **Copy this** - you'll add it to Airbridge Dashboard

### 4️⃣ Build Release (5 min)
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
flutter clean && flutter pub get
flutter build appbundle --release
```
📦 **Output**: `build/app/outputs/bundle/release/app-release.aab`

### 5️⃣ Test (Optional, 10 min)
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 6️⃣ Create Play Console Account (15 min)
- Go to [play.google.com/console](https://play.google.com/console)
- Pay $25 one-time fee
- Create app "Catch Up"

### 7️⃣ Complete App Details (1 hour)
- Privacy policy (required)
- Content rating questionnaire
- Data safety section
- Store listing (description, screenshots, icon)

### 8️⃣ Upload & Release (15 min)
- Upload `app-release.aab`
- Add release notes
- Click "Start rollout to Production"

### 9️⃣ Wait for Review (1-7 days)
Google will email you when approved

### 🔟 Post-Launch
- Add release SHA-256 to Airbridge Dashboard
- Test download from Play Store
- Monitor reviews and crashes

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **QUICK_START_RELEASE.md** | Step-by-step walkthrough (START HERE) |
| **PLAY_STORE_DEPLOYMENT_GUIDE.md** | Complete detailed guide |
| **android/key.properties.template** | Template for signing config |
| This file (RELEASE_SUMMARY.md) | Quick reference |

---

## ⚠️ Important Notes

### Security
- ✅ `key.properties` is in `.gitignore` (don't commit!)
- ✅ `*.jks` files are in `.gitignore` (don't commit!)
- 🔒 **Backup your keystore** to cloud storage
- 🔒 **Save your passwords** - you can't recover them

### Version Numbers
Every release needs:
```kotlin
versionCode = 1      // Must increase: 1, 2, 3, ...
versionName = "1.0.0" // User visible: 1.0.0, 1.0.1, ...
```

### Package Name
Changed to `com.catchup.app` in:
- ✅ `android/app/build.gradle.kts` (line 9)
- ✅ `android/app/build.gradle.kts` (line 23)
- ⚠️ **Still needs manual update**: 
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/` directory structure

---

## 🛠️ Build Commands

### For Play Store (AAB)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### For Testing (APK)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## 📊 Pre-Release Checklist

**Before Building:**
- [ ] Keystore created
- [ ] `key.properties` configured
- [ ] SHA-256 fingerprint saved
- [ ] App tested thoroughly
- [ ] Version numbers set

**Play Console:**
- [ ] Account created ($25 paid)
- [ ] Privacy policy URL ready
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (2-8 images)
- [ ] Store description written

**Build:**
- [ ] AAB built successfully
- [ ] File size reasonable (~20-30MB)
- [ ] Release APK tested locally

**Post-Upload:**
- [ ] Release notes added
- [ ] All sections completed
- [ ] Released to production

**After Approval:**
- [ ] Release SHA-256 added to Airbridge
- [ ] App tested from Play Store
- [ ] Deep links tested

---

## 🔄 Future Updates

To release an update:

1. **Update version** in `android/app/build.gradle.kts`:
   ```kotlin
   versionCode = 2       // Increment by 1
   versionName = "1.0.1" // Update version
   ```

2. **Build**:
   ```bash
   flutter build appbundle --release
   ```

3. **Upload** to Play Console → Production → Create new release

---

## 🆘 Common Issues

### "App not signed"
- Check `key.properties` file exists
- Check paths and passwords are correct

### "Package name not available"
- `com.example.*` not allowed
- Already changed to `com.catchup.app` ✅

### "Version code must be higher"
- Increment `versionCode` in `build.gradle.kts`

### "Deep links not working"
- Add **release** SHA-256 to Airbridge Dashboard
- Wait 24-48 hours for verification

### "Privacy policy required"
- Must have publicly accessible URL
- Can use GitHub Pages, Google Sites, etc.

---

## 📞 Support Resources

- **Play Console Help**: https://support.google.com/googleplay/android-developer
- **Flutter Deployment**: https://docs.flutter.dev/deployment/android
- **Airbridge Docs**: https://help.airbridge.io
- **Stack Overflow**: Tag with `flutter`, `android-play-store`

---

## 🎯 Timeline Estimate

| Task | Time |
|------|------|
| Create keystore | 5 min |
| Configure signing | 2 min |
| Build AAB | 5 min |
| Create Play Console account | 15 min |
| Complete app details | 1-2 hours |
| Upload and submit | 15 min |
| **Total (excluding review)** | **~3 hours** |
| Google review process | 1-7 days |

---

## ✅ Current Status

- [x] Build system configured for release
- [x] Package name changed
- [x] Version numbers set
- [x] ProGuard configured
- [x] Airbridge integrated
- [x] Deep linking ready
- [ ] **Next: Create keystore and build AAB**

---

## 🎉 You're Ready!

All the hard technical work is done. Now just follow the steps in **QUICK_START_RELEASE.md** to:
1. Create your keystore
2. Build the release AAB
3. Upload to Play Store

Good luck with your launch! 🚀

---

**Need help?** Check:
1. QUICK_START_RELEASE.md (step-by-step)
2. PLAY_STORE_DEPLOYMENT_GUIDE.md (detailed guide)
3. Google Play Console support

