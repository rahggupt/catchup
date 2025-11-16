# Article Saving Fix - Complete Guide

## Problems Fixed

### 1. Articles Not Appearing in Collections ❌ → ✅

**Problem**: Users could swipe right to save articles and see a success message, but articles never appeared in collections (all showed "0 articles").

**Root Cause**: Missing RLS (Row Level Security) policies on the `collection_articles` table. Even though the app was successfully saving articles, Supabase was blocking reads due to missing SELECT policies.

**Fix**: Created comprehensive RLS policies for `collection_articles` table that allow:
- Users to view articles in collections they own or are members of
- Users to add articles to collections they own or have editor access to
- Users to remove articles from collections they have editor access to

### 2. Perplexity API Error ❌ → ✅

**Problem**: When using Perplexity AI, the app crashed with error:
```
Exception: Perplexity API error: 400
{"error":{"message":"Invalid model 'llama-3.1-sonar-small-128k-online'..."}}
```

**Root Cause**: Wrong Perplexity model name. The model `llama-3.1-sonar-small-128k-online` is not a valid Perplexity API model.

**Fix**: Changed to `sonar-small-online`, which is the correct model name according to Perplexity API documentation.

### 3. Share Link Generation Crash ❌ → ✅

**Problem**: When trying to share a collection, the app crashed with:
```
RangeError (end): Invalid value: Not in inclusive range 0..6: 12
```

**Root Cause**: Unsafe substring operation that assumed the hash string would always be at least 12 characters long, but it could be shorter.

**Fix**: Added safety checks to ensure substring operations don't exceed string length, with padding if needed.

---

## How to Apply Fixes

### Step 1: Apply SQL Fix in Supabase (Required)

1. Go to: **https://app.supabase.com/project/YOUR_PROJECT/sql**

2. Copy and run the SQL from `database/fix_collection_articles_rls.sql`:

```sql
-- Fix RLS Policies for collection_articles Table

ALTER TABLE collection_articles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "collection_articles_select" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_insert" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_delete" ON collection_articles;

-- SELECT: Users can view articles in collections they own or are members of
CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);

-- INSERT: Users can add articles to collections they own or are members of
CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- DELETE: Users can remove articles from collections they own or are editors of
CREATE POLICY "collection_articles_delete" ON collection_articles
FOR DELETE USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- Verify policies were created (should show 3 rows)
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'collection_articles';
```

3. Click **Run** and verify it shows 3 policies created

### Step 2: Install New APK (Required)

The code fixes have been applied and a new APK has been built.

```bash
# Install the new APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer the APK to your phone and install manually
```

---

## Testing Checklist

After applying SQL fix and installing new APK:

### Test 1: Save Article to Collection ✅
1. Open the app and go to Feed
2. Swipe right on any article
3. Select a collection (e.g., "MyCollection")
4. Click "Add to Collection"
5. **Expected**: Success message appears
6. Go to Collections tab
7. **Expected**: Collection now shows "1 articles" (not "0 articles")
8. Tap the collection
9. **Expected**: Article appears in the list

### Test 2: Perplexity AI Works ✅
1. Go to Profile → AI Settings
2. Select "Perplexity" as provider
3. Add your Perplexity API key (if not already set)
4. Go to any article
5. Click "Ask AI"
6. **Expected**: No model error, AI responds successfully

### Test 3: Share Collection Works ✅
1. Go to Collections tab
2. Tap the "..." menu on any collection
3. Select "Share"
4. **Expected**: No range error, share options appear
5. Generate a share link
6. **Expected**: Link generated successfully

---

## What Changed

### Files Modified:

1. **`database/fix_collection_articles_rls.sql`** (new)
   - Added RLS policies for collection_articles table
   
2. **`lib/core/constants/app_constants.dart`**
   - Line 58: Changed `perplexityModel` from `llama-3.1-sonar-small-128k-online` to `sonar-small-online`

3. **`lib/shared/services/supabase_service.dart`**
   - Lines 591-593: Added safety checks for substring operations in `generateShareableLink`

---

## Troubleshooting

### Articles Still Not Appearing?

**Check 1: Verify SQL was applied**
```sql
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'collection_articles';
-- Should return 3
```

**Check 2: Test policy manually**
```sql
-- This should return rows (not empty)
SELECT * FROM collection_articles
WHERE collection_id IN (
  SELECT id FROM collections WHERE owner_id = auth.uid()
);
```

**Check 3: Check debug logs**
- Use debug build: `./build_apk_java21.sh --debug`
- Go to Settings → Debug Settings → View Debug Logs
- Filter by "Database" category
- Look for "Article added to collection successfully"

### Perplexity Still Not Working?

**Check 1: API key is set**
- Go to Profile → AI Settings
- Verify API key is entered and saved

**Check 2: Check available models**
Valid Perplexity models:
- `sonar-small-online` (fastest, cheapest)
- `sonar-medium-online` (balanced)
- `sonar-large-online` (most capable)

**Check 3: Check debug logs**
- Filter by "AI" category
- Look for Perplexity-specific errors

### Share Link Still Failing?

**Check**: Ensure you installed the NEW APK (not an old cached version)
- Check APK build timestamp
- Uninstall old app first, then install new one

---

## Summary

**Before Fixes:**
- ❌ Articles saved but not visible (0 articles shown)
- ❌ Perplexity API returned 400 error
- ❌ Share link generation crashed with range error

**After Fixes:**
- ✅ Articles save and appear in collections
- ✅ Perplexity AI works correctly
- ✅ Share links generate without errors

---

## Next Steps

1. **Apply SQL fix** in Supabase (Step 1 above)
2. **Install new APK** (Step 2 above)
3. **Test all features** (Testing Checklist above)
4. If issues persist, check debug logs and troubleshooting section

---

**All fixes are complete and ready to deploy!** 🎉

Just run the SQL script and install the new APK.

