# 🔧 Deep Link Debug Fix - Complete Guide

## ✅ What Was Fixed

### 1. Database Relationship Error ✅
**Error**: `Could not find a relationship between 'collection_members' and 'users'`

**Root Cause**: The query was using `SELECT *` which tried to fetch all related tables, including broken relationships.

**Fix**: Changed to explicit column selection:
```dart
.select('''
  id,
  name,
  owner_id,
  privacy,
  collaborator_ids,
  stats,
  shareable_link,
  shareable_token,
  share_enabled,
  cover_image,
  preview,
  created_at,
  updated_at
''')
```

This avoids trying to join the `collection_members` table that has relationship issues.

---

### 2. Enhanced Debug Logging ✅

Added comprehensive logging throughout the deep link flow:

**Deep Link Initialization:**
```
🚀 [DeepLink] Initializing deep link listener
📱 [DeepLink] Airbridge SDK ready to receive links
✅ [DeepLink] Deep link handler registered successfully
```

**When Link is Clicked:**
```
📬 [DeepLink] ========== DEEP LINK RECEIVED ==========
🔗 [DeepLink] Full URL: https://catchup.airbridge.io/c/eq2sgv000000
🔄 [DeepLink] Processing deep link: ...
🌐 [DeepLink] Parsed URI:
   - Scheme: https
   - Host: catchup.airbridge.io
   - Path: /c/eq2sgv000000
🎯 [DeepLink] Extracted token: "eq2sgv000000"
```

**Database Query:**
```
🔍 [DeepLink] Fetching collection by token: eq2sgv000000
📊 [DeepLink] Query response: Found/Not found
✅ [DeepLink] Collection found: Collection Name (ID: xxx)
```

**If Collection Not Found:**
```
❌ [DeepLink] Collection not found for token: "eq2sgv000000"

🔍 [DeepLink] Troubleshooting steps:
   1. Check if token exists in database
   2. Check if share_enabled = true
   3. Check RLS policy
   4. Try disabling RLS temporarily
```

---

## 🗄️ Database Fix Required

### Run This SQL in Supabase

```sql
-- Step 1: Drop existing policy if any
DROP POLICY IF EXISTS "Anyone can view shared collections" ON collections;

-- Step 2: Create the RLS policy for public access
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);

-- Step 3: Verify the token exists
SELECT 
  id,
  name,
  shareable_token,
  share_enabled,
  owner_id,
  created_at
FROM collections 
WHERE shareable_token = 'eq2sgv000000';

-- Step 4: If token exists but share_enabled is false, enable it
UPDATE collections
SET share_enabled = true
WHERE shareable_token = 'eq2sgv000000';

-- Step 5: Test the query (same as the app uses)
SELECT 
  id,
  name,
  owner_id,
  privacy,
  collaborator_ids,
  stats,
  shareable_link,
  shareable_token,
  share_enabled,
  cover_image,
  preview,
  created_at,
  updated_at
FROM collections 
WHERE shareable_token = 'eq2sgv000000'
  AND share_enabled = true;
```

**Expected Result:** Should return 1 row with your collection data.

---

## 📱 Install & Test

### 1. Install the New APK

```bash
# Uninstall old version
adb uninstall com.example.mindmap_aggregator

# Install new version with debug logs
adb install build/app/outputs/flutter-apk/app-release-debug.apk
```

### 2. Test the Deep Link

**Method A: Click in Browser**
1. Open browser on phone
2. Go to: `https://catchup.airbridge.io/c/eq2sgv000000`
3. App should open

**Method B: ADB Command**
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://catchup.airbridge.io/c/eq2sgv000000"
```

### 3. Check Debug Logs

In the app:
1. Go to **Profile** tab
2. Scroll down to **Debug Settings**
3. Tap **View Debug Logs**
4. Filter by **Category: DeepLink**

You should see:
```
📬 [DeepLink] ========== DEEP LINK RECEIVED ==========
🔗 [DeepLink] Full URL: https://catchup.airbridge.io/c/eq2sgv000000
🎯 [DeepLink] Extracted token: "eq2sgv000000"
🔍 [DeepLink] Fetching collection by token: eq2sgv000000
✅ [DeepLink] Collection found: Your Collection Name
✅ [DeepLink] Navigation successful!
```

---

## 🐛 Troubleshooting Guide

### Issue 1: "Collection not found"

**Check in Supabase SQL Editor:**

```sql
-- Does the token exist?
SELECT * FROM collections WHERE shareable_token = 'eq2sgv000000';
```

**If NO RESULTS:**
- Token doesn't exist in database
- Generate a new share link from the app

**If RESULTS BUT share_enabled = false:**
```sql
UPDATE collections
SET share_enabled = true
WHERE shareable_token = 'eq2sgv000000';
```

---

### Issue 2: "Permission denied" or Empty Result

**Check RLS Policies:**

```sql
-- View current policies
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'collections';
```

**If no policy for public SELECT, create it:**

```sql
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);
```

---

### Issue 3: Deep Link Not Triggering App

**Verify AndroidManifest.xml has intent filters:**

Should already be in place:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    
    <data android:scheme="https"
          android:host="catchup.airbridge.io"
          android:pathPrefix="/c/"/>
</intent-filter>
```

**For automatic app opening (no browser prompt):**
Add your SHA-256 fingerprint to Airbridge Dashboard:

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android \
  | grep SHA256
```

---

### Issue 4: App Crashes When Opening Link

**Check ADB Logcat:**

```bash
adb logcat | grep -i "crash\|exception\|error"
```

**Check App Debug Logs:**
Profile → Debug Settings → View Debug Logs → Filter by ERROR

---

## 🔍 Debug Log Examples

### Successful Deep Link Flow:

```
[Info] 🚀 [DeepLink] Initializing deep link listener
[Info] ✅ [DeepLink] Deep link handler registered successfully
[Info] 📬 [DeepLink] ========== DEEP LINK RECEIVED ==========
[Info] 🔗 [DeepLink] Full URL: https://catchup.airbridge.io/c/eq2sgv000000
[Info] 🎯 [DeepLink] Extracted token: "eq2sgv000000"
[Info] 📂 [DeepLink] ========== LOADING COLLECTION ==========
[Info] 🔍 [DeepLink] Fetching collection by token: eq2sgv000000
[Info] 📊 [DeepLink] Query response: Found
[Info] ✅ [DeepLink] Collection found!
[Info]    - Name: My Awesome Collection
[Info]    - ID: abc-123-def
[Info]    - Articles: 5
[Info] 🧭 [DeepLink] Navigating to collection details...
[Info] ✅ [DeepLink] Navigation successful!
```

### Failed Flow (Token Not Found):

```
[Info] 📬 [DeepLink] ========== DEEP LINK RECEIVED ==========
[Info] 🔗 [DeepLink] Full URL: https://catchup.airbridge.io/c/eq2sgv000000
[Info] 🎯 [DeepLink] Extracted token: "eq2sgv000000"
[Info] 🔍 [DeepLink] Fetching collection by token: eq2sgv000000
[Warning] ❌ [DeepLink] No collection found for token: eq2sgv000000
[Warning] 🔍 [DeepLink] Troubleshooting steps:
[Warning]    1. Check if token exists in database: SELECT * FROM collections WHERE shareable_token = 'eq2sgv000000'
[Warning]    2. Check if share_enabled = true
[Warning]    3. Check RLS policy
```

---

## ✅ Verification Checklist

Before testing, ensure:

- [ ] New APK installed (`app-release-debug.apk`)
- [ ] RLS policy created in Supabase
- [ ] Token exists in database: `SELECT * FROM collections WHERE shareable_token = 'eq2sgv000000'`
- [ ] `share_enabled = true` for that collection
- [ ] Airbridge configuration correct in `build.gradle.kts`
- [ ] Deep link handler initialized in `main_navigation.dart`

---

## 📊 What to Expect

### Success Case:
1. Click link → App opens
2. Collection details screen appears
3. Articles are visible
4. No errors in debug logs

### Failure Case with Debug Info:
1. Click link → App opens
2. Error message appears: "Collection not found: eq2sgv000000"
3. Debug logs show exact failure point
4. Troubleshooting steps shown in logs

---

## 🆘 Still Not Working?

### Test with SQL Query:

Run this in Supabase SQL Editor:

```sql
-- Temporarily disable RLS to test
ALTER TABLE collections DISABLE ROW LEVEL SECURITY;

-- Try the query
SELECT * FROM collections WHERE shareable_token = 'eq2sgv000000';

-- Re-enable RLS
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
```

If it works without RLS but not with RLS, it's definitely a policy issue.

### Generate New Share Link:

Instead of using `eq2sgv000000`, generate a fresh link:

1. Open app
2. Go to Collections
3. Open any collection
4. Tap Share button
5. Copy the NEW link
6. Test that new link

---

## 🔄 Next Steps

1. **Install new APK** with debug logs
2. **Run SQL commands** in Supabase to create RLS policy
3. **Click the link** and watch for errors
4. **Check debug logs** in Profile → Debug Settings
5. **Share screenshots** of the logs if still not working

The debug logs will tell us exactly where it's failing! 🎯

---

**Build Info:**
- APK: `app-release-debug.apk`
- Size: 55MB
- Debug Mode: Enabled
- Date: November 29, 2025

