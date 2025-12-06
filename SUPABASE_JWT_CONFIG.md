# ⚠️ CRITICAL: Supabase JWT Configuration

## 🚨 Action Required

You MUST update the JWT expiry setting in your Supabase Dashboard for the session persistence fix to work properly!

---

## 📝 Step-by-Step Instructions

### 1. Open Supabase Dashboard

Go to: https://supabase.com/dashboard

### 2. Select Your Project

Click on your "Catch Up" project

### 3. Navigate to Authentication Settings

**Path**: Dashboard → Settings → Authentication

Or direct URL:
```
https://supabase.com/dashboard/project/YOUR_PROJECT_ID/settings/auth
```

### 4. Find JWT Settings Section

Scroll down to find the **"JWT Settings"** section

### 5. Update JWT Expiry

**Current value**: `3600` (1 hour)  
**New value**: `2592000` (30 days)

**Calculation**:
```
30 days × 24 hours × 60 minutes × 60 seconds = 2,592,000 seconds
```

### 6. Save Changes

Click the **"Save"** button at the bottom of the page

### 7. Verify

After saving, you should see:
```
JWT Expiry: 2592000 seconds
```

---

## ✅ Verification

To verify the change worked:

1. Log in to your app
2. Check the console logs - should see:
   ```
   ✅ Supabase initialized with automatic session persistence
   📅 Session timeout configured for 30 days
   ⚠️  IMPORTANT: Set JWT expiry in Supabase Dashboard to 2592000 seconds (30 days)
   ```
3. Close and reopen the app multiple times - should stay logged in
4. Wait several hours - should still be logged in

---

## 🔧 Alternative Values

If you want a different session timeout:

| Duration | Seconds | Days |
|----------|---------|------|
| 1 hour (default) | 3600 | 0.04 |
| 1 day | 86400 | 1 |
| 7 days | 604800 | 7 |
| 30 days | 2592000 | 30 |
| 90 days | 7776000 | 90 |

**Remember**: Also update `sessionTimeoutDays` in `lib/core/constants/app_constants.dart` to match!

---

## ❓ Why Is This Needed?

The JWT (JSON Web Token) is what Supabase uses to authenticate users. It has an expiration time built into it.

- **Without this change**: Tokens expire after 1 hour → Users get logged out
- **With this change**: Tokens expire after 30 days → Users stay logged in

The Flutter app automatically refreshes tokens before they expire, but only if the JWT expiry time allows it!

---

## 🐛 Troubleshooting

### Issue: Still getting logged out after 1 hour

**Check**:
1. Did you save the changes in Supabase Dashboard?
2. Did you restart the app after making the change?
3. Check the JWT expiry value in the dashboard - is it 2592000?

**Fix**:
- Go back to Supabase Dashboard and verify the setting
- Make sure you clicked "Save"
- Uninstall and reinstall the app to clear old tokens

### Issue: Can't find JWT Settings

**Location**:
- Dashboard → Settings (left sidebar)
- Click "Authentication" tab
- Scroll down to "JWT Settings"

### Issue: Changes not taking effect

**Solution**:
1. Log out of the app
2. Uninstall the app
3. Reinstall the app
4. Log in again
5. New tokens will have the new expiry time

---

## 📸 Screenshot Reference

The JWT Settings section looks like this:

```
┌─────────────────────────────────────┐
│ JWT Settings                        │
├─────────────────────────────────────┤
│                                     │
│ JWT Expiry                          │
│ ┌─────────────────────────────────┐ │
│ │ 2592000                         │ │ ← Change this
│ └─────────────────────────────────┘ │
│ seconds                             │
│                                     │
│ [Save]                              │
└─────────────────────────────────────┘
```

---

## ✅ Done!

Once you've updated this setting, your users will stay logged in for 30 days! 🎉

**Next**: Install the new APK and test the fixes!

```bash
adb install ~/Desktop/catchup-fixed.apk
```

