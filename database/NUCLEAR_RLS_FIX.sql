-- =====================================================
-- NUCLEAR OPTION: Complete RLS Reset for Collections
-- =====================================================
-- This aggressively removes ALL policies and recreates them
-- Use this if COMPLETE_RLS_FIX.sql didn't work
-- =====================================================

-- =====================================================
-- STEP 1: Temporarily disable RLS to clear everything
-- =====================================================

ALTER TABLE collections DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: Drop ALL policies using dynamic SQL
-- This ensures we catch any policy we might have missed
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on collections table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'collections') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON collections', r.policyname);
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- Double-check: manually drop known policy names
DROP POLICY IF EXISTS "Users can view own and shared collections" ON collections;
DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
DROP POLICY IF EXISTS "collection_access" ON collections;
DROP POLICY IF EXISTS "Users can create collections" ON collections;
DROP POLICY IF EXISTS "Users can insert collections" ON collections;
DROP POLICY IF EXISTS "Users can update own collections" ON collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete their own collections" ON collections;
DROP POLICY IF EXISTS "Users can view collections they're members of" ON collections;
DROP POLICY IF EXISTS "collection_member_access" ON collections;
DROP POLICY IF EXISTS "collections_select_policy" ON collections;
DROP POLICY IF EXISTS "collections_insert_policy" ON collections;
DROP POLICY IF EXISTS "collections_update_policy" ON collections;
DROP POLICY IF EXISTS "collections_delete_policy" ON collections;

-- =====================================================
-- STEP 3: Verify all policies are gone
-- =====================================================

DO $$ 
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'collections';
    
    IF policy_count > 0 THEN
        RAISE EXCEPTION 'Still have % policies on collections table! Something is wrong.', policy_count;
    ELSE
        RAISE NOTICE '✓ All policies successfully removed from collections table';
    END IF;
END $$;

-- =====================================================
-- STEP 4: Create ONLY 4 new simple policies
-- =====================================================

-- Policy 1: SELECT - View own collections OR member collections
CREATE POLICY "collections_select_policy"
ON collections FOR SELECT
USING (
  auth.uid() = owner_id
  OR
  EXISTS (
    SELECT 1 
    FROM collection_members
    WHERE collection_members.collection_id = collections.id
    AND collection_members.user_id = auth.uid()
  )
);

-- Policy 2: INSERT - Create collections
CREATE POLICY "collections_insert_policy"
ON collections FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Policy 3: UPDATE - Update own collections
CREATE POLICY "collections_update_policy"
ON collections FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- Policy 4: DELETE - Delete own collections
CREATE POLICY "collections_delete_policy"
ON collections FOR DELETE
USING (auth.uid() = owner_id);

-- =====================================================
-- STEP 5: Re-enable RLS
-- =====================================================

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 6: Also fix collection_members policies (might be causing issues)
-- =====================================================

-- Check if collection_members has problematic policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all existing policies on collection_members
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'collection_members') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON collection_members', r.policyname);
        RAISE NOTICE 'Dropped collection_members policy: %', r.policyname;
    END LOOP;
END $$;

-- Create simple policies for collection_members
CREATE POLICY "collection_members_select_policy"
ON collection_members FOR SELECT
USING (true);  -- Allow reading all members (used by collections SELECT policy)

CREATE POLICY "collection_members_insert_policy"
ON collection_members FOR INSERT
WITH CHECK (
  -- Only collection owners can add members
  EXISTS (
    SELECT 1 FROM collections 
    WHERE collections.id = collection_members.collection_id 
    AND collections.owner_id = auth.uid()
  )
);

CREATE POLICY "collection_members_delete_policy"
ON collection_members FOR DELETE
USING (
  -- Only collection owners can remove members
  EXISTS (
    SELECT 1 FROM collections 
    WHERE collections.id = collection_members.collection_id 
    AND collections.owner_id = auth.uid()
  )
);

ALTER TABLE collection_members ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- VERIFICATION: Show final state
-- =====================================================

-- Show collections policies (should be exactly 4)
SELECT 
  'collections' as table_name,
  policyname,
  cmd,
  substring(qual::text, 1, 60) || '...' as policy_rule
FROM pg_policies 
WHERE tablename = 'collections'
ORDER BY cmd, policyname;

-- Show collection_members policies (should be 3)
SELECT 
  'collection_members' as table_name,
  policyname,
  cmd,
  substring(qual::text, 1, 60) || '...' as policy_rule
FROM pg_policies 
WHERE tablename = 'collection_members'
ORDER BY cmd, policyname;

-- Count check
SELECT 
  tablename,
  COUNT(*) as policy_count,
  CASE 
    WHEN tablename = 'collections' AND COUNT(*) = 4 THEN '✓ CORRECT'
    WHEN tablename = 'collection_members' AND COUNT(*) = 3 THEN '✓ CORRECT'
    ELSE '✗ UNEXPECTED COUNT'
  END as status
FROM pg_policies 
WHERE tablename IN ('collections', 'collection_members')
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- SUCCESS! 🎉
-- Expected results:
-- - collections: 4 policies
-- - collection_members: 3 policies
--
-- Now restart your Flutter app and test:
-- 1. Feed should load without RLS errors
-- 2. Can view collections
-- 3. Can create new collections
-- 4. Can add articles to collections
-- =====================================================

