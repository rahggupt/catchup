-- =============================================================================
-- Default Collections Migration Script
-- =============================================================================
-- Purpose: Create default collections for all existing users who don't have any
-- Run this script in Supabase SQL Editor or via Supabase CLI
-- =============================================================================

-- Function to create default collections for all existing users
CREATE OR REPLACE FUNCTION create_default_collections_for_existing_users()
RETURNS TABLE (
  user_count integer,
  collections_created integer
) AS $$
DECLARE
  user_record RECORD;
  user_counter integer := 0;
  collection_counter integer := 0;
BEGIN
  -- Loop through all users
  FOR user_record IN 
    SELECT id FROM auth.users 
    ORDER BY created_at ASC
  LOOP
    user_counter := user_counter + 1;
    
    -- Check if user has any collections
    IF NOT EXISTS (
      SELECT 1 FROM collections 
      WHERE owner_id = user_record.id
    ) THEN
      -- Create default collections for this user
      BEGIN
        -- 1. Saved Articles
        INSERT INTO collections (
          name, 
          description,
          owner_id, 
          privacy, 
          created_at
        )
        VALUES (
          'Saved Articles',
          'Articles saved for later reading',
          user_record.id,
          'private',
          NOW()
        );
        collection_counter := collection_counter + 1;
        
        -- 2. Read Later
        INSERT INTO collections (
          name, 
          description,
          owner_id, 
          privacy, 
          created_at
        )
        VALUES (
          'Read Later',
          'Queue of articles to read',
          user_record.id,
          'private',
          NOW()
        );
        collection_counter := collection_counter + 1;
        
        -- 3. Favorites
        INSERT INTO collections (
          name, 
          description,
          owner_id, 
          privacy, 
          created_at
        )
        VALUES (
          'Favorites',
          'Your favorite articles',
          user_record.id,
          'private',
          NOW()
        );
        collection_counter := collection_counter + 1;
        
        RAISE NOTICE 'Created 3 default collections for user: %', user_record.id;
        
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create collections for user %: %', user_record.id, SQLERRM;
      END;
    ELSE
      RAISE NOTICE 'User % already has collections, skipping', user_record.id;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT user_counter, collection_counter;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Execute the function
-- =============================================================================
SELECT * FROM create_default_collections_for_existing_users();

-- =============================================================================
-- Verify results
-- =============================================================================
-- Check how many users now have collections
SELECT 
  COUNT(DISTINCT owner_id) as users_with_collections,
  COUNT(*) as total_collections
FROM collections;

-- Show collection count per user
SELECT 
  owner_id,
  COUNT(*) as collection_count,
  array_agg(name ORDER BY created_at) as collection_names
FROM collections
GROUP BY owner_id
ORDER BY collection_count DESC, owner_id;

-- =============================================================================
-- Optional: Drop the function after use
-- =============================================================================
-- Uncomment the line below if you want to remove the function after migration
-- DROP FUNCTION IF EXISTS create_default_collections_for_existing_users();

-- =============================================================================
-- NOTES
-- =============================================================================
-- 1. This script is idempotent - safe to run multiple times
-- 2. Users who already have collections will be skipped
-- 3. New users will get default collections automatically on signup (via app code)
-- 4. If you need to re-run for a specific user, delete their collections first
-- 5. The function returns: (user_count, collections_created)
--    - user_count: Total users processed
--    - collections_created: Total new collections created
--
-- Example output:
-- user_count | collections_created
-- -----------|--------------------
--         10 |                 30
--
-- This means 10 users were processed and 30 collections were created (3 per user)
-- =============================================================================

