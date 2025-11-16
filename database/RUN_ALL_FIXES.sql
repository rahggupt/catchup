-- =====================================================
-- RUN ALL FIXES - Copy and paste this entire file into Supabase SQL Editor
-- This will fix both errors shown in the screenshots:
-- 1. Collections RLS infinite recursion (42P17)
-- 2. Ask AI invalid UUID error (22P02)
-- =====================================================

-- =====================================================
-- FIX 1: Collections RLS Infinite Recursion
-- =====================================================

-- Drop existing policies that cause recursion
DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
DROP POLICY IF EXISTS "Users can create collections" ON collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete their own collections" ON collections;
DROP POLICY IF EXISTS "Users can view collections they're members of" ON collections;

-- Recreate policies without recursion
CREATE POLICY "Users can view their own collections"
ON collections FOR SELECT
USING (
  auth.uid() = owner_id
  OR
  EXISTS (
    SELECT 1 FROM collection_members
    WHERE collection_members.collection_id = collections.id
    AND collection_members.user_id = auth.uid()
  )
);

CREATE POLICY "Users can create collections"
ON collections FOR INSERT
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own collections"
ON collections FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own collections"
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

-- Check collections policies (should show 4 policies)
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'collections'
ORDER BY policyname;

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
-- - 4 policies for collections table
-- - is_nullable = YES for chats.collection_id
-- Then both fixes are applied successfully!
-- 
-- Now restart your Flutter app and test:
-- 1. Feed screen should load without errors
-- 2. Ask AI should work for articles
-- 3. Collections can be created and saved
-- =====================================================

