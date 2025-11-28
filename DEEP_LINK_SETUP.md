# Deep Linking Setup Guide for CatchUp

## Overview

This guide explains how to set up proper deep linking so that shared collection links:
1. Open directly in the app if installed
2. Redirect to Google Play Store if app is not installed
3. Work seamlessly across all platforms

## Current Implementation

Share links are now generated in HTTPS format:
```
https://catchup.app/c/{token}
```

## Setup Options

### Option 1: Firebase Dynamic Links (Recommended for MVP)

**Pros**: Free, managed by Google, auto Play Store redirect, no backend needed
**Cons**: Being deprecated (but still works, alternatives: Branch.io or custom solution)

#### Steps:

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Create new project or use existing
   - Add Android app with package name: `com.mindmap.aggregator`

2. **Enable Dynamic Links**
   - In Firebase Console → Dynamic Links
   - Set up a URL prefix (e.g., `catchup.page.link`)

3. **Add Firebase Dependencies**
   
   In `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.0
     firebase_dynamic_links: ^5.4.0
   ```

4. **Initialize Firebase**
   
   In `lib/main.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(MyApp());
   }
   ```

5. **Update Share Link Generation**
   
   In `supabase_service.dart`, replace:
   ```dart
   return 'https://catchup.app/c/$token';
   ```
   
   With:
   ```dart
   return 'https://catchup.page.link/c?token=$token&apn=com.mindmap.aggregator&afl=https://play.google.com/store/apps/details?id=com.mindmap.aggregator';
   ```

6. **Handle Incoming Links**
   
   Create `lib/shared/services/deep_link_service.dart`:
   ```dart
   import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
   
   class DeepLinkService {
     static Future<void> initDynamicLinks(BuildContext context) async {
       // Handle link when app is opened from terminated state
       final PendingDynamicLinkData? initialLink = 
           await FirebaseDynamicLinks.instance.getInitialLink();
       
       if (initialLink != null) {
         _handleDeepLink(context, initialLink.link);
       }
       
       // Handle link when app is in background/foreground
       FirebaseDynamicLinks.instance.onLink.listen(
         (dynamicLinkData) {
           _handleDeepLink(context, dynamicLinkData.link);
         },
       );
     }
     
     static void _handleDeepLink(BuildContext context, Uri deepLink) {
       final token = deepLink.queryParameters['token'];
       if (token != null) {
         // Navigate to collection screen
         Navigator.pushNamed(context, '/collection', arguments: {'token': token});
       }
     }
   }
   ```

7. **Configure AndroidManifest.xml**
   
   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <activity>
     <intent-filter android:autoVerify="true">
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="https" android:host="catchup.page.link" />
     </intent-filter>
   </activity>
   ```

### Option 2: Custom Domain with App Links (Production Ready)

**Pros**: Full control, no third-party dependency, professional
**Cons**: Requires backend, domain, and HTTPS hosting

#### Steps:

1. **Set Up Landing Page**
   
   Create a simple webpage at `https://catchup.app/c/{token}`:
   - Detect if user is on Android
   - Check if app is installed using intent:// scheme
   - If not installed, redirect to Play Store
   - If installed, open app with deep link

   Example HTML:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <meta charset="UTF-8">
     <title>CatchUp Collection</title>
     <script>
       const token = window.location.pathname.split('/').pop();
       const appScheme = `catchup://collection/${token}`;
       const playStore = 'https://play.google.com/store/apps/details?id=com.mindmap.aggregator';
       
       // Try to open app
       window.location.href = appScheme;
       
       // Fallback to Play Store after 2 seconds
       setTimeout(() => {
         window.location.href = playStore;
       }, 2000);
     </script>
   </head>
   <body>
     <h1>Opening CatchUp...</h1>
     <p>If the app doesn't open, <a href="${playStore}">download it here</a>.</p>
   </body>
   </html>
   ```

2. **Configure App Links**
   
   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <intent-filter android:autoVerify="true">
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="https" android:host="catchup.app" android:pathPrefix="/c" />
   </intent-filter>
   ```

3. **Create Digital Asset Links File**
   
   Host at `https://catchup.app/.well-known/assetlinks.json`:
   ```json
   [{
     "relation": ["delegate_permission/common.handle_all_urls"],
     "target": {
       "namespace": "android_app",
       "package_name": "com.mindmap.aggregator",
       "sha256_cert_fingerprints": [
         "YOUR_APP_SHA256_FINGERPRINT"
       ]
     }
   }]
   ```
   
   Get fingerprint with:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

4. **Handle Incoming Links**
   
   Install `app_links` package:
   ```yaml
   dependencies:
     app_links: ^3.4.5
   ```
   
   In `lib/main.dart`:
   ```dart
   import 'package:app_links/app_links.dart';
   
   class _MyAppState extends State<MyApp> {
     late AppLinks _appLinks;
     
     @override
     void initState() {
       super.initState();
       _initDeepLinks();
     }
     
     Future<void> _initDeepLinks() async {
       _appLinks = AppLinks();
       
       // Handle initial link
       final uri = await _appLinks.getInitialLink();
       if (uri != null) {
         _handleDeepLink(uri);
       }
       
       // Handle links while app is open
       _appLinks.uriLinkStream.listen((uri) {
         _handleDeepLink(uri);
       });
     }
     
     void _handleDeepLink(Uri uri) {
       if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
         final token = uri.pathSegments[1];
         // Navigate to collection
         Navigator.pushNamed(context, '/collection', arguments: {'token': token});
       }
     }
   }
   ```

### Option 3: Branch.io (Commercial, Most Features)

**Pros**: Best analytics, A/B testing, attribution, deferred deep linking
**Cons**: Paid service ($299/month for pro features)

Visit: https://branch.io

## Testing Deep Links

### Test on Android:

1. **Using ADB**:
   ```bash
   adb shell am start -W -a android.intent.action.VIEW \
     -d "https://catchup.app/c/abc123" \
     com.mindmap.aggregator
   ```

2. **Using Browser**:
   - Open Chrome on emulator/device
   - Navigate to your share URL
   - Should prompt to open app or redirect to Play Store

3. **Verify App Links**:
   ```bash
   adb shell dumpsys package domain-preferred-apps
   ```

## Recommended Approach

**For immediate deployment**: Use **Option 1 (Firebase Dynamic Links)** 
- Quick to set up (2-3 hours)
- Works reliably
- Free
- Handles Play Store redirect automatically

**For long-term production**: Migrate to **Option 2 (Custom Domain)**
- Professional appearance
- Full control
- No third-party dependency

## Implementation Checklist

- [ ] Choose deep linking solution (Firebase/Custom/Branch)
- [ ] Update `generateShareableLink` in `supabase_service.dart`
- [ ] Add required dependencies to `pubspec.yaml`
- [ ] Configure `AndroidManifest.xml` with intent filters
- [ ] Create deep link handler service
- [ ] Add route handling for collection token
- [ ] Test deep links with ADB
- [ ] Test on real device
- [ ] Verify Play Store redirect works
- [ ] Update share UI to show proper URL

## Current Status

✅ Share links now use HTTPS format
⏳ Deep link handling needs to be implemented (choose option above)
⏳ App Links verification needed
⏳ Play Store redirect logic needed

## Next Steps

1. Decide on deep linking approach (recommend Firebase for MVP)
2. Follow steps for chosen option
3. Test thoroughly before release
4. Update this documentation with actual implementation details

