-- Fix infinite recursion in collections RLS policies
-- The issue: owner_id policy references collections table while evaluating collections table

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
DROP POLICY IF EXISTS "Users can create collections" ON collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON collections;
DROP POLICY IF EXISTS "Users can delete their own collections" ON collections;
DROP POLICY IF EXISTS "Users can view collections they're members of" ON collections;

-- Recreate policies without recursion

-- SELECT policy: Users can view collections they own OR are members of
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

-- INSERT policy: Users can create collections
CREATE POLICY "Users can create collections"
ON collections FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- UPDATE policy: Only owners can update collections
CREATE POLICY "Users can update their own collections"
ON collections FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- DELETE policy: Only owners can delete collections
CREATE POLICY "Users can delete their own collections"
ON collections FOR DELETE
USING (auth.uid() = owner_id);

-- Verify RLS is enabled
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

