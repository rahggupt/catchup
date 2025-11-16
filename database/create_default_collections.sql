-- =============================================================================
-- MyCollection Migration Script
-- =============================================================================
-- Purpose: 
--   1. Create "MyCollection" for all users (new and existing)
--   2. Clean up old default collections if they're empty
-- Run this script in Supabase SQL Editor or via Supabase CLI
-- =============================================================================

DO $$
DECLARE
  user_record RECORD;
  collection_count INTEGER;
  old_defaults TEXT[] := ARRAY['Saved Articles', 'Read Later', 'Favorites'];
  old_default_name TEXT;
  old_default_id UUID;
  article_count INTEGER;
  users_processed INTEGER := 0;
  collections_created INTEGER := 0;
  collections_deleted INTEGER := 0;
BEGIN
  RAISE NOTICE 'Starting MyCollection migration...';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  
  -- Loop through all users
  FOR user_record IN 
    SELECT id, email, created_at
    FROM auth.users
    ORDER BY created_at ASC
  LOOP
    users_processed := users_processed + 1;
    RAISE NOTICE '';
    RAISE NOTICE 'Processing user % (%)...', users_processed, user_record.email;
    
    -- Step 1: Delete old default collections if they're empty (no articles)
    FOREACH old_default_name IN ARRAY old_defaults
    LOOP
      -- Find the collection
      SELECT id INTO old_default_id
      FROM collections
      WHERE owner_id = user_record.id 
        AND name = old_default_name
      LIMIT 1;
      
      IF old_default_id IS NOT NULL THEN
        -- Check if it has any articles
        SELECT COUNT(*) INTO article_count
        FROM collection_articles
        WHERE collection_id = old_default_id;
        
        IF article_count = 0 THEN
          -- Delete empty old default collection
          DELETE FROM collections WHERE id = old_default_id;
          collections_deleted := collections_deleted + 1;
          RAISE NOTICE '  ✓ Deleted empty collection: "%"', old_default_name;
        ELSE
          RAISE NOTICE '  ○ Keeping "%" (has % articles)', old_default_name, article_count;
        END IF;
      END IF;
    END LOOP;
    
    -- Step 2: Check if user has "MyCollection"
    SELECT COUNT(*) INTO collection_count
    FROM collections
    WHERE owner_id = user_record.id 
      AND name = 'MyCollection';
    
    -- Step 3: Create "MyCollection" if it doesn't exist
    IF collection_count = 0 THEN
      INSERT INTO collections (owner_id, name, privacy, preview, created_at)
      VALUES (
        user_record.id,
        'MyCollection',
        'private',
        'Your personal collection of curated articles',
        NOW()
      )
      ON CONFLICT DO NOTHING;
      
      collections_created := collections_created + 1;
      RAISE NOTICE '  ✓ Created "MyCollection"';
    ELSE
      RAISE NOTICE '  ○ "MyCollection" already exists';
    END IF;
    
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE 'Migration Complete!';
  RAISE NOTICE '  Users processed: %', users_processed;
  RAISE NOTICE '  MyCollections created: %', collections_created;
  RAISE NOTICE '  Empty defaults deleted: %', collections_deleted;
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Migration failed: %', SQLERRM;
  RAISE;
END $$;

-- =============================================================================
-- Verify results
-- =============================================================================
SELECT 
  'Total users with MyCollection' as metric,
  COUNT(*) as count
FROM collections
WHERE name = 'MyCollection'

UNION ALL

SELECT 
  'Total users with collections' as metric,
  COUNT(DISTINCT owner_id) as count
FROM collections

UNION ALL

SELECT 
  'Total collections' as metric,
  COUNT(*) as count
FROM collections;

-- Show all collections per user
SELECT 
  u.email,
  COUNT(*) as collection_count,
  array_agg(c.name ORDER BY c.created_at) as collection_names
FROM auth.users u
LEFT JOIN collections c ON c.owner_id = u.id
GROUP BY u.id, u.email
ORDER BY collection_count DESC, u.email;

-- =============================================================================
-- NOTES
-- =============================================================================
-- 1. This script is idempotent - safe to run multiple times
-- 2. Removes old default collections ("Saved Articles", "Read Later", "Favorites") only if empty
-- 3. Creates "MyCollection" for all users who don't have it yet
-- 4. New users will get "MyCollection" automatically on signup (via app code)
-- 5. Existing users will get "MyCollection" on their next login (via app code)
-- =============================================================================
