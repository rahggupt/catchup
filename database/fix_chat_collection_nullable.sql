-- Fix: Make collection_id nullable in chats table
-- This allows article-based chats to exist without being linked to a collection

-- Make collection_id nullable
ALTER TABLE chats 
ALTER COLUMN collection_id DROP NOT NULL;

-- Update any existing chats with invalid collection_id to NULL
-- (In case there are any with article_ prefix that failed)
UPDATE chats 
SET collection_id = NULL 
WHERE collection_id IS NOT NULL 
  AND NOT EXISTS (
    SELECT 1 FROM collections WHERE collections.id = chats.collection_id::uuid
  );

-- Verify the change
SELECT 
  column_name, 
  data_type, 
  is_nullable 
FROM information_schema.columns 
WHERE table_name = 'chats' AND column_name = 'collection_id';

