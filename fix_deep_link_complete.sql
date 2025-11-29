-- Complete Deep Link Fix for Supabase
-- Run this entire script in Supabase SQL Editor

-- ============================================
-- Step 1: Create RLS Policy for Public Access
-- ============================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Anyone can view shared collections" ON collections;

-- Create policy to allow anyone to view shared collections
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);

-- ============================================
-- Step 2: Verify Token Exists
-- ============================================

-- Check if your specific token exists
SELECT 
  id,
  name,
  shareable_token,
  share_enabled,
  owner_id,
  created_at,
  stats
FROM collections 
WHERE shareable_token = 'eq2sgv000000';

-- If the above returns no results, the token doesn't exist!
-- You need to generate a share link from the app.

-- ============================================
-- Step 3: Enable Sharing (if token exists)
-- ============================================

-- If token exists but share_enabled is false, enable it:
UPDATE collections
SET share_enabled = true
WHERE shareable_token = 'eq2sgv000000';

-- ============================================
-- Step 4: Test the Query (Same as App Uses)
-- ============================================

-- This is the exact query the app will run
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

-- If this returns a row, the deep link should work!
-- If this returns nothing, check:
--   1. Token doesn't exist
--   2. share_enabled is false
--   3. RLS policy not working

-- ============================================
-- Step 5: Verify RLS Policy Created
-- ============================================

-- Check that the policy exists
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'collections'
  AND policyname = 'Anyone can view shared collections';

-- Should return 1 row showing the policy details

-- ============================================
-- Step 6: List All Shareable Collections
-- ============================================

-- See all collections that can be shared
SELECT 
  id,
  name,
  shareable_token,
  share_enabled,
  stats->>'article_count' as article_count,
  created_at
FROM collections 
WHERE share_enabled = true
ORDER BY created_at DESC;

-- ============================================
-- TROUBLESHOOTING QUERIES
-- ============================================

-- If still not working, run these diagnostic queries:

-- Check if RLS is enabled on collections table
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'collections';
-- rowsecurity should be 't' (true)

-- View ALL policies on collections (not just our new one)
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'collections';

-- Check if there are any conflicting policies that might block access

-- ============================================
-- EMERGENCY: Temporarily Disable RLS (for testing only!)
-- ============================================

-- WARNING: Only use this for testing, not in production!
-- This will allow ALL users to see ALL collections
-- Uncomment the line below ONLY for testing:

-- ALTER TABLE collections DISABLE ROW LEVEL SECURITY;

-- After testing, RE-ENABLE it:
-- ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- ============================================
-- DONE!
-- ============================================

-- After running this script:
-- 1. Install the new APK (app-release-debug.apk)
-- 2. Click the deep link: https://catchup.airbridge.io/c/eq2sgv000000
-- 3. Check debug logs in Profile → Debug Settings
-- 4. Collection should open!

