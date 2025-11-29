# 🔍 Debug: Collection Not Found for Token `eq2sgv000000`

## The Problem

When you click the link [https://catchup.airbridge.io/c/eq2sgv000000](https://catchup.airbridge.io/c/eq2sgv000000), you get "item not found" error.

The deep link handler is working correctly and extracting the token `eq2sgv000000`, but the `getCollectionByToken` query is returning null.

## What the Code Does

```dart
// In supabase_service.dart
Future<CollectionModel?> getCollectionByToken(String token) async {
  final response = await _client
      .from('collections')
      .select('*')
      .eq('shareable_token', token)        // Must match: 'eq2sgv000000'
      .eq('share_enabled', true)            // Must be true
      .maybeSingle();
  
  if (response == null) {
    return null;  // ❌ This is what's happening!
  }
  
  return CollectionModel.fromJson(response);
}
```

## Possible Causes

### 1. Token Doesn't Exist in Database ⚠️

The most likely issue is that the collection with this token doesn't exist.

**Check this in Supabase:**

```sql
-- Check if the token exists
SELECT 
  id, 
  name, 
  shareable_token, 
  share_enabled,
  created_at,
  owner_id
FROM collections 
WHERE shareable_token = 'eq2sgv000000';
```

**Expected result:**
- If **no rows**: Token doesn't exist → Need to generate share link
- If **rows found**: Continue to next check

---

### 2. Share Not Enabled ⚠️

The collection exists but `share_enabled` is false.

**Check this:**

```sql
-- Check if sharing is enabled
SELECT 
  id, 
  name, 
  share_enabled,
  shareable_token
FROM collections 
WHERE shareable_token = 'eq2sgv000000';
```

**If `share_enabled = false`:**

```sql
-- Enable sharing
UPDATE collections
SET share_enabled = true
WHERE shareable_token = 'eq2sgv000000';
```

---

### 3. RLS Policy Blocking Access 🔒

Row Level Security might be preventing anonymous users from viewing shared collections.

**Check RLS policies:**

```sql
-- Check if RLS is enabled
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE tablename = 'collections';
```

**If RLS is enabled, you need a policy for public access to shared collections:**

```sql
-- Create policy to allow reading shared collections
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);
```

This policy allows anyone (even unauthenticated users) to read collections where `share_enabled = true`.

---

### 4. Wrong Token Generated ⚠️

The token in the database might be different from what's in the URL.

**Check all tokens:**

```sql
-- List all shareable collections
SELECT 
  id, 
  name, 
  shareable_token,
  share_enabled,
  created_at
FROM collections 
WHERE share_enabled = true
ORDER BY created_at DESC;
```

Compare the tokens in the database with your URL.

---

## How to Fix

### Step 1: Verify the Collection Exists

Go to **Supabase Dashboard → Table Editor → collections**

Find the collection you want to share and check:
- [ ] `id` exists
- [ ] `name` is correct
- [ ] `shareable_token` column exists
- [ ] `share_enabled` column exists

---

### Step 2: Generate Share Link Properly

In your app:

1. Go to the collection you want to share
2. Tap the **Share** button
3. The app will call `generateShareableLink(collectionId)`
4. This should:
   - Create a token in the database
   - Set `share_enabled = true`
   - Return the URL

**Check the share button code:**

The share button should be calling something like:

```dart
final shareLink = await supabaseService.generateShareableLink(collection.id);
```

If this isn't working, the token might not be saved to the database.

---

### Step 3: Manually Create Share Link (Temporary Fix)

If the app isn't creating tokens properly, you can manually create one:

```sql
-- Manually set up sharing for a collection
UPDATE collections
SET 
  shareable_token = 'eq2sgv000000',
  share_enabled = true
WHERE id = 'YOUR_COLLECTION_ID_HERE';
```

Replace `YOUR_COLLECTION_ID_HERE` with the actual collection ID.

---

### Step 4: Check RLS Policies

**Current RLS policies for collections:**

```sql
-- View all policies on collections table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'collections';
```

**You need this policy:**

```sql
-- Drop existing policy if needed
DROP POLICY IF EXISTS "Anyone can view shared collections" ON collections;

-- Create new policy for public access
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);
```

This ensures that even users who aren't logged in can view shared collections.

---

## Test After Fix

### 1. Verify in Database

```sql
-- This should return your collection
SELECT * 
FROM collections 
WHERE shareable_token = 'eq2sgv000000'
  AND share_enabled = true;
```

### 2. Test the URL

Click the link: [https://catchup.airbridge.io/c/eq2sgv000000](https://catchup.airbridge.io/c/eq2sgv000000)

### 3. Check App Logs

In your app, go to **Profile → Debug Settings** and check for:

```
✅ Deep link received: https://catchup.airbridge.io/c/eq2sgv000000
✅ Processing deep link: https://catchup.airbridge.io/c/eq2sgv000000
✅ Loading shared collection with token: eq2sgv000000
✅ Fetching collection by token
```

If you see:
```
❌ No collection found for token
```

Then the database query is failing.

---

## Quick Test with Different Token

Try creating a new share link in the app:

1. Open any collection
2. Tap Share
3. Copy the new URL
4. Test that URL

If the new URL works but `eq2sgv000000` doesn't, then that specific token doesn't exist in the database.

---

## Database Schema Check

Make sure your `collections` table has these columns:

```sql
-- Check table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'collections'
  AND column_name IN ('shareable_token', 'share_enabled');
```

**Expected:**
- `shareable_token` → `text` or `varchar`
- `share_enabled` → `boolean`

If these columns don't exist, you need to add them:

```sql
-- Add columns if missing
ALTER TABLE collections 
ADD COLUMN IF NOT EXISTS shareable_token TEXT UNIQUE;

ALTER TABLE collections 
ADD COLUMN IF NOT EXISTS share_enabled BOOLEAN DEFAULT false;
```

---

## Summary Checklist

- [ ] Token `eq2sgv000000` exists in database
- [ ] `share_enabled = true` for that collection
- [ ] RLS policy allows public access to shared collections
- [ ] App has network access to Supabase
- [ ] Collection isn't deleted
- [ ] Using the latest APK (`app-release-debug.apk`)

---

## Still Not Working?

### Get the actual database value:

In **Supabase SQL Editor**, run:

```sql
-- Get all info about this specific token
SELECT 
  id,
  name,
  shareable_token,
  share_enabled,
  owner_id,
  created_at,
  updated_at,
  (SELECT email FROM auth.users WHERE id = owner_id) as owner_email
FROM collections 
WHERE shareable_token ILIKE '%eq2sgv%';  -- Case-insensitive search
```

This will show if the token exists with any variation.

### Check app logs:

```bash
adb logcat | grep -i "collection\|deeplink\|eq2sgv"
```

### Try without RLS:

Temporarily disable RLS to test:

```sql
-- WARNING: Only for testing!
ALTER TABLE collections DISABLE ROW LEVEL SECURITY;
```

Test the link, then re-enable:

```sql
-- Re-enable after testing
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
```

---

**Most Common Fix:** Run this SQL in Supabase:

```sql
-- Create the RLS policy for shared collections
CREATE POLICY IF NOT EXISTS "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);

-- Verify it worked
SELECT * FROM collections WHERE shareable_token = 'eq2sgv000000';
```

Then test the link again!

