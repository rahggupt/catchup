-- Fix Collections Visibility Issue
-- This ensures users can see their own collections

-- Drop existing problematic policies
DROP POLICY IF EXISTS "collections_select_policy" ON collections;
DROP POLICY IF EXISTS "collections_insert_policy" ON collections;
DROP POLICY IF EXISTS "collections_update_policy" ON collections;
DROP POLICY IF EXISTS "collections_delete_policy" ON collections;

-- Create simple, clear RLS policies for collections

-- 1. SELECT: Users can view their own collections and collections they're members of
CREATE POLICY "collections_select_policy" ON collections
FOR SELECT
USING (
  auth.uid() = owner_id 
  OR 
  privacy = 'public'
  OR
  id IN (
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);

-- 2. INSERT: Users can create their own collections
CREATE POLICY "collections_insert_policy" ON collections
FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- 3. UPDATE: Only owners can update their collections
CREATE POLICY "collections_update_policy" ON collections
FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- 4. DELETE: Only owners can delete their collections
CREATE POLICY "collections_delete_policy" ON collections
FOR DELETE
USING (auth.uid() = owner_id);

-- Ensure RLS is enabled
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- Verify policies
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
ORDER BY policyname;

