-- =====================================================
-- COMPLETE FIX: Collections RLS Infinite Recursion
-- =====================================================
-- This script completely cleans up ALL duplicate and problematic policies
-- and recreates only 4 simple policies without recursion.
--
-- Problem: The collections table has 9 policies (should have 4)
-- - Multiple duplicates causing conflicts
-- - Complex policies with collaborator_ids causing recursion
-- =====================================================

-- =====================================================
-- STEP 1: Drop ALL existing policies (all 9 from database)
-- =====================================================

-- Drop all SELECT policies (3 total)
DROP POLICY IF EXISTS "Users can view own and shared collections" ON collections;
DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
DROP POLICY IF EXISTS "collection_access" ON collections;

-- Drop all INSERT policies (2 total)
DROP POLICY IF EXISTS "Users can create collections" ON collections;
DROP POLICY IF EXISTS "Users can insert collections" ON collections;

-- Drop all UPDATE policies (2 total)
DROP POLICY IF EXISTS "Users can update own collections" ON collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON collections;

-- Drop all DELETE policies (2 total)
DROP POLICY IF EXISTS "Users can delete own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete their own collections" ON collections;

-- Drop any other potential policies that might exist
DROP POLICY IF EXISTS "Users can view collections they're members of" ON collections;
DROP POLICY IF EXISTS "collection_member_access" ON collections;

-- Drop the new policy names too (in case they were created in a previous run)
DROP POLICY IF EXISTS "collections_select_policy" ON collections;
DROP POLICY IF EXISTS "collections_insert_policy" ON collections;
DROP POLICY IF EXISTS "collections_update_policy" ON collections;
DROP POLICY IF EXISTS "collections_delete_policy" ON collections;

-- =====================================================
-- STEP 2: Create ONLY 4 simple policies (no recursion)
-- =====================================================

-- Policy 1: SELECT - Users can view their own collections OR collections they're members of
CREATE POLICY "collections_select_policy"
ON collections FOR SELECT
USING (
  -- User is the owner
  auth.uid() = owner_id
  OR
  -- User is a member of the collection
  EXISTS (
    SELECT 1 
    FROM collection_members
    WHERE collection_members.collection_id = collections.id
    AND collection_members.user_id = auth.uid()
  )
);

-- Policy 2: INSERT - Users can create collections (they must be the owner)
CREATE POLICY "collections_insert_policy"
ON collections FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Policy 3: UPDATE - Users can update only their own collections
CREATE POLICY "collections_update_policy"
ON collections FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- Policy 4: DELETE - Users can delete only their own collections
CREATE POLICY "collections_delete_policy"
ON collections FOR DELETE
USING (auth.uid() = owner_id);

-- =====================================================
-- STEP 3: Ensure RLS is enabled
-- =====================================================

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- VERIFICATION: Check the policies were created correctly
-- =====================================================

-- Should show exactly 4 policies
SELECT 
  policyname,
  cmd,
  CASE 
    WHEN length(qual::text) > 80 THEN substring(qual::text, 1, 80) || '...'
    ELSE qual::text
  END as qual_preview,
  CASE 
    WHEN length(with_check::text) > 80 THEN substring(with_check::text, 1, 80) || '...'
    ELSE with_check::text
  END as with_check_preview
FROM pg_policies 
WHERE tablename = 'collections'
ORDER BY cmd, policyname;

-- =====================================================
-- EXPECTED RESULT:
-- Should show exactly 4 rows:
-- 1. collections_delete_policy | DELETE
-- 2. collections_insert_policy | INSERT
-- 3. collections_select_policy | SELECT
-- 4. collections_update_policy | UPDATE
-- =====================================================

-- Count policies (should be 4)
SELECT 
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) = 4 THEN '✓ CORRECT: Exactly 4 policies'
    ELSE '✗ ERROR: Expected 4 policies but found ' || COUNT(*)
  END as status
FROM pg_policies 
WHERE tablename = 'collections';

-- =====================================================
-- SUCCESS! 🎉
-- If you see 4 policies above, the fix is complete.
-- Now restart your Flutter app and test:
-- 1. Feed screen should load without RLS errors
-- 2. Collections should be visible
-- 3. Can create new collections
-- 4. Can save articles to collections
-- =====================================================

