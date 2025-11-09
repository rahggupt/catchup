-- Fix for collection_articles table constraints
-- Run this in Supabase SQL Editor

-- Check current constraints
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'collection_articles';

-- Drop the foreign key constraint on article_id if it exists
-- This allows us to reference articles that might not be in the articles table yet
ALTER TABLE collection_articles
DROP CONSTRAINT IF EXISTS collection_articles_article_id_fkey;

-- Add it back without the constraint (or make it DEFERRABLE)
-- Option 1: No constraint (articles can be referenced without being in articles table)
-- Nothing to do - just remove the constraint

-- Option 2: Make constraint deferrable (check at end of transaction)
ALTER TABLE collection_articles
ADD CONSTRAINT collection_articles_article_id_fkey
FOREIGN KEY (article_id)
REFERENCES articles(id)
DEFERRABLE INITIALLY DEFERRED;

-- Verify the fix
SELECT * FROM collection_articles LIMIT 5;

