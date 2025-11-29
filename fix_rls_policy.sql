-- Fix RLS Policy for Shared Collections
-- Run this in Supabase SQL Editor

-- Step 1: Drop existing policy if it exists (won't error if it doesn't exist)
DROP POLICY IF EXISTS "Anyone can view shared collections" ON collections;

-- Step 2: Create the policy for public access to shared collections
CREATE POLICY "Anyone can view shared collections"
ON collections
FOR SELECT
USING (share_enabled = true);

-- Step 3: Verify the policy was created
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

-- Step 4: Test the query that the app uses
SELECT 
  id,
  name,
  shareable_token,
  share_enabled,
  owner_id
FROM collections 
WHERE shareable_token = 'eq2sgv000000'
  AND share_enabled = true;

