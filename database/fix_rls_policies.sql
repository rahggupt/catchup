-- Fix infinite recursion in collection_members RLS policy
-- The issue occurs when a policy references the same table it's protecting

-- Drop all existing policies on collection_members table
DROP POLICY IF EXISTS "collection_members_policy" ON collection_members;
DROP POLICY IF EXISTS "collection_members_select" ON collection_members;
DROP POLICY IF EXISTS "collection_members_insert" ON collection_members;
DROP POLICY IF EXISTS "collection_members_update" ON collection_members;
DROP POLICY IF EXISTS "collection_members_delete" ON collection_members;

-- Create separate policies for each operation to avoid recursion

-- SELECT: Users can view memberships for collections they own or are members of
CREATE POLICY "collection_members_select" ON collection_members
  FOR SELECT USING (
    user_id = auth.uid() OR 
    collection_id IN (
      SELECT id FROM collections WHERE owner_id = auth.uid()
    )
  );

-- INSERT: Only collection owners can add members
CREATE POLICY "collection_members_insert" ON collection_members
  FOR INSERT WITH CHECK (
    collection_id IN (
      SELECT id FROM collections WHERE owner_id = auth.uid()
    )
  );

-- UPDATE: Only collection owners can update member status
CREATE POLICY "collection_members_update" ON collection_members
  FOR UPDATE USING (
    collection_id IN (
      SELECT id FROM collections WHERE owner_id = auth.uid()
    )
  );

-- DELETE: Only collection owners or the members themselves can remove memberships
CREATE POLICY "collection_members_delete" ON collection_members
  FOR DELETE USING (
    user_id = auth.uid() OR
    collection_id IN (
      SELECT id FROM collections WHERE owner_id = auth.uid()
    )
  );

-- Verify the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'collection_members';

COMMENT ON TABLE collection_members IS 'Stores collection membership with RLS policies preventing infinite recursion';

