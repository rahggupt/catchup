-- =====================================================
-- RUN ALL FIXES - Copy and paste this entire file into Supabase SQL Editor
-- This will fix both errors shown in the screenshots:
-- 1. Collections RLS infinite recursion (42P17)
-- 2. Ask AI invalid UUID error (22P02)
-- =====================================================

-- =====================================================
-- FIX 1: Collections RLS Infinite Recursion
-- =====================================================
-- Complete cleanup of ALL duplicate and problematic policies

-- Drop ALL existing policies (including duplicates and old policies)
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

-- Drop any other potential policies
DROP POLICY IF EXISTS "Users can view collections they're members of" ON collections;
DROP POLICY IF EXISTS "collection_member_access" ON collections;

-- Drop the new policy names too (in case they were created in a previous run)
DROP POLICY IF EXISTS "collections_select_policy" ON collections;
DROP POLICY IF EXISTS "collections_insert_policy" ON collections;
DROP POLICY IF EXISTS "collections_update_policy" ON collections;
DROP POLICY IF EXISTS "collections_delete_policy" ON collections;

-- Recreate ONLY 4 simple policies (no recursion, no duplicates)

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

-- Verify RLS is enabled
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- FIX 2: Chat Collection ID - Make Nullable
-- =====================================================

-- Make collection_id nullable (allows article chats without collection)
ALTER TABLE chats 
ALTER COLUMN collection_id DROP NOT NULL;

-- Clean up any invalid collection_id values
UPDATE chats 
SET collection_id = NULL 
WHERE collection_id IS NOT NULL 
  AND NOT EXISTS (
    SELECT 1 FROM collections WHERE collections.id = chats.collection_id::uuid
  );

-- =====================================================
-- VERIFICATION: Check if fixes were applied
-- =====================================================

-- Check collections policies (should show EXACTLY 4 policies)
SELECT 
  policyname,
  cmd,
  CASE 
    WHEN length(qual::text) > 60 THEN substring(qual::text, 1, 60) || '...'
    ELSE qual::text
  END as qual_preview
FROM pg_policies 
WHERE tablename = 'collections'
ORDER BY cmd, policyname;

-- Expected result: 4 policies with these names:
-- 1. collections_delete_policy (DELETE)
-- 2. collections_insert_policy (INSERT)
-- 3. collections_select_policy (SELECT)
-- 4. collections_update_policy (UPDATE)

-- Count total policies (must be exactly 4)
SELECT 
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) = 4 THEN '✓ CORRECT: Exactly 4 policies'
    ELSE '✗ ERROR: Expected 4 policies but found ' || COUNT(*)
  END as status
FROM pg_policies 
WHERE tablename = 'collections';

-- Check chats.collection_id is nullable (should show YES)
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'chats' 
  AND column_name = 'collection_id';

-- =====================================================
-- SUCCESS! 🎉
-- If you see:
-- - EXACTLY 4 policies for collections table (not 9!)
--   - collections_delete_policy
--   - collections_insert_policy
--   - collections_select_policy
--   - collections_update_policy
-- - is_nullable = YES for chats.collection_id
-- Then both fixes are applied successfully!
-- 
-- Now restart your Flutter app and test:
-- 1. Feed screen should load without RLS recursion errors
-- 2. Collections should be visible (no infinite recursion)
-- 3. Can create new collections
-- 4. Can save articles to collections
-- 5. Ask AI should work for individual articles
-- =====================================================

