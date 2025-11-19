-- Fix duplicate sources by adding unique constraint and removing duplicates

-- Step 1: Identify and display duplicates
SELECT user_id, url, COUNT(*) as count
FROM sources
GROUP BY user_id, url
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Step 2: Keep only the most recent source for each (user_id, url) combination
-- Delete older duplicates
DELETE FROM sources a
USING sources b
WHERE a.id < b.id 
  AND a.user_id = b.user_id 
  AND a.url = b.url;

-- Step 3: Add unique constraint to prevent future duplicates
-- This ensures each user can only have one source with a specific URL
ALTER TABLE sources 
DROP CONSTRAINT IF EXISTS sources_user_url_unique;

ALTER TABLE sources 
ADD CONSTRAINT sources_user_url_unique 
UNIQUE (user_id, url);

-- Step 4: Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_sources_user_url 
ON sources(user_id, url);

-- Step 5: Verify the fix
SELECT 
  user_id, 
  url, 
  COUNT(*) as count
FROM sources
GROUP BY user_id, url
HAVING COUNT(*) > 1;
-- Should return 0 rows if successful

-- Step 6: Display total sources per user
SELECT 
  user_id,
  COUNT(*) as total_sources,
  COUNT(DISTINCT url) as unique_urls
FROM sources
GROUP BY user_id
ORDER BY total_sources DESC;

COMMENT ON CONSTRAINT sources_user_url_unique ON sources IS 'Prevents users from adding the same source URL multiple times';

