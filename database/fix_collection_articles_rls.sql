-- Fix RLS Policies for collection_articles Table
-- This allows users to add articles to their collections

-- Enable RLS on collection_articles table
ALTER TABLE collection_articles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "collection_articles_select" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_insert" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_delete" ON collection_articles;

-- SELECT: Users can view articles in collections they own or are members of
CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);

-- INSERT: Users can add articles to collections they own or are members of (editor role)
CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- DELETE: Users can remove articles from collections they own or are editors of
CREATE POLICY "collection_articles_delete" ON collection_articles
FOR DELETE USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'collection_articles'
ORDER BY policyname;

