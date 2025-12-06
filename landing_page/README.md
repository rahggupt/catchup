# 📱 CatchUp Landing Page

This landing page provides a seamless experience for users clicking on shared collection links.

## 🎯 Features

### For Users WITH the App Installed
1. **Auto-opens the app** - Page automatically attempts to open CatchUp app
2. **Direct to collection** - Opens directly to the shared collection
3. **No extra steps** - Seamless experience

### For Users WITHOUT the App
1. **Detects app is not installed** - Automatically detects if app didn't open
2. **Shows download button** - Provides direct APK download link
3. **Installation instructions** - Guides user through installation
4. **Returns to link** - After installation, user can return to open collection

## 🚀 Deployment Options

### Option 1: GitHub Pages (Recommended - FREE)

1. **Enable GitHub Pages**:
   - Go to: https://github.com/rahggupt/catchup/settings/pages
   - Under "Source": Select **main** branch
   - Under "Folder": Select **/ (root)** or **/landing_page** if you keep it in subfolder
   - Click **Save**

2. **Access your landing page**:
   ```
   https://rahggupt.github.io/catchup/landing_page/?c=TOKEN
   ```
   
   Or if you move `index.html` to root:
   ```
   https://rahggupt.github.io/catchup/?c=TOKEN
   ```

3. **Host your APK on GitHub Releases**:
   ```bash
   # Create a release with your APK
   # Go to: https://github.com/rahggupt/catchup/releases/new
   # 
   # - Tag version: v1.0.0
   # - Release title: CatchUp v1.0.0
   # - Upload: app-release.apk (rename to catchup.apk)
   # - Click "Publish release"
   ```

4. **Update the landing page**:
   - Open `index.html`
   - Update line 141:
     ```javascript
     const GITHUB_REPO = 'rahggupt/catchup'; // Your username/repo
     ```
   - The APK will be available at:
     ```
     https://github.com/rahggupt/catchup/releases/latest/download/catchup.apk
     ```

### Option 2: Host APK Directly in Repo (Alternative)

If you want to host APK in the repo itself:

1. Create a folder: `releases/`
2. Add your APK: `releases/catchup.apk`
3. Update `index.html` line 142:
   ```javascript
   const APK_DOWNLOAD_URL = `https://rahggupt.github.io/catchup/releases/catchup.apk`;
   ```

**Note**: APKs are large binary files. GitHub has a 100MB file size limit. Releases are preferred.

### Option 3: Custom Domain (Advanced)

If you have your own domain:

1. Follow GitHub Pages custom domain setup
2. Update links in your app to use your domain
3. Update `index.html` accordingly

## 📝 How It Works

### User Flow

1. **User receives link**: `https://rahggupt.github.io/catchup/?c=abc123`
2. **Page loads**: Shows "Opening CatchUp app..." message
3. **Auto-attempts to open app**: Uses deep link `catchup://c/abc123`

**Scenario A - App Installed**:
- App opens immediately
- User sees the shared collection
- ✅ Done!

**Scenario B - App NOT Installed**:
- Page waits 2.5 seconds
- Detects app didn't open (page still visible)
- Shows "Download CatchUp APK" button
- Shows installation instructions
- User downloads → installs → returns to link → opens collection
- ✅ Done!

## 🔧 Configuration

### Update These Values in `index.html`

**Line 141** - Your GitHub repository:
```javascript
const GITHUB_REPO = 'rahggupt/catchup';
```

**Line 142** - APK download URL:
```javascript
// Option 1: GitHub Releases (Recommended)
const APK_DOWNLOAD_URL = `https://github.com/${GITHUB_REPO}/releases/latest/download/catchup.apk`;

// Option 2: Host in repo
const APK_DOWNLOAD_URL = 'https://rahggupt.github.io/catchup/releases/catchup.apk';

// Option 3: External hosting
const APK_DOWNLOAD_URL = 'https://your-server.com/catchup.apk';
```

## 📦 Creating a GitHub Release

### Quick Guide

1. **Build your release APK**:
   ```bash
   cd "/Users/rahulg/Catch Up/mindmap_aggregator"
   flutter build apk --release
   cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/catchup.apk
   ```

2. **Create release on GitHub**:
   - Go to: https://github.com/rahggupt/catchup/releases/new
   - **Tag**: `v1.0.0`
   - **Title**: `CatchUp v1.0.0 - Initial Release`
   - **Description**:
     ```
     # CatchUp v1.0.0
     
     First release of CatchUp!
     
     ## Features
     - Personalized news feed
     - Smart collections
     - AI-powered insights
     - Share collections with friends
     
     ## Installation
     1. Download catchup.apk
     2. Enable "Install from Unknown Sources"
     3. Install the APK
     4. Enjoy!
     ```
   - **Attach file**: Upload `catchup.apk`
   - **Click**: "Publish release"

3. **Test the download**:
   ```
   https://github.com/rahggupt/catchup/releases/latest/download/catchup.apk
   ```

## 🧪 Testing

### Test with App Installed
1. Install your app on device
2. Open: `https://rahggupt.github.io/catchup/?c=test123`
3. Should auto-open app after 0.5 seconds
4. ✅ App opens to collection

### Test without App
1. Uninstall app from device
2. Open same link
3. Should show download button after 2.5 seconds
4. Click download → installs APK
5. Return to link → app opens
6. ✅ Collection loads

### Test Deep Link Format
Your token format: `79syv8000000`

Full URL:
```
https://rahggupt.github.io/catchup/?c=79syv8000000
```

## 🎨 Customization

### Change Colors
Edit the CSS in `<style>` section:

```css
/* Main gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Button gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Change Auto-Open Delay
Line 161:
```javascript
setTimeout(() => {
    openApp();
}, 500); // Change this value (milliseconds)
```

### Change Detection Timeout
Line 152:
```javascript
setTimeout(() => {
    // Detection logic
}, 2500); // Change this value (milliseconds)
```

## 📱 Update Your App

Update the shareable link generation in your app:

**File**: `lib/shared/services/supabase_service.dart`

```dart
// Change from custom scheme to GitHub Pages URL
return 'https://rahggupt.github.io/catchup/?c=$token';
```

Already done in your current build! ✅

## 🔍 Troubleshooting

### Issue: Download button not appearing
- **Check**: Browser console for errors
- **Fix**: Verify APK_DOWNLOAD_URL is correct

### Issue: App not opening
- **Check**: Custom scheme `catchup://` is configured in AndroidManifest.xml
- **Fix**: Rebuild app with proper deep link configuration

### Issue: 404 on APK download
- **Check**: GitHub release exists and APK is uploaded
- **Check**: Filename is exactly `catchup.apk`
- **Fix**: Create release properly (see guide above)

### Issue: Page not loading
- **Check**: GitHub Pages is enabled
- **Check**: URL is correct
- **Fix**: Wait 2-3 minutes after enabling GitHub Pages

## 📊 Analytics (Optional)

Add Google Analytics or similar:

```html
<!-- Add before closing </head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=YOUR-ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'YOUR-ID');
</script>
```

Track events:
```javascript
// When app opens
gtag('event', 'app_opened', { 'collection_token': token });

// When download starts
gtag('event', 'apk_download', { 'collection_token': token });
```

## 🌐 Sharing

When users share collections, they'll get:

**WhatsApp/Telegram/Email**:
```
📰 Check out my collection "Tech News" on CatchUp!

👉 Click to open:
https://rahggupt.github.io/catchup/?c=79syv8000000

📲 Don't have CatchUp? Let me know!
```

**The link is BLUE and CLICKABLE!** ✅

---

## 🎉 Benefits

✅ **Free hosting** (GitHub Pages)  
✅ **Clickable links** (HTTPS URLs)  
✅ **Works without Play Store**  
✅ **Auto-opens if installed**  
✅ **Easy APK distribution**  
✅ **Professional user experience**  
✅ **Update anytime** (just push to GitHub)  

---

**Need help?** Check the main guides or ask for assistance! 🚀
