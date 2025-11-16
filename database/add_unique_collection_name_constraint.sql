-- Add unique constraint for collection name per user
-- This ensures each user can't have duplicate collection names

-- First, check if constraint already exists and drop it if it does
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_collection_name_per_user'
    ) THEN
        ALTER TABLE collections DROP CONSTRAINT unique_collection_name_per_user;
        RAISE NOTICE 'Dropped existing constraint unique_collection_name_per_user';
    END IF;
END $$;

-- Add the unique constraint
ALTER TABLE collections
ADD CONSTRAINT unique_collection_name_per_user 
UNIQUE (owner_id, name);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_collections_owner_name 
ON collections(owner_id, name);

-- Verify the constraint was added
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_collection_name_per_user'
    ) THEN
        RAISE NOTICE '✓ Constraint successfully added: unique_collection_name_per_user';
        RAISE NOTICE '✓ Index created: idx_collections_owner_name';
    ELSE
        RAISE WARNING '✗ Failed to add constraint unique_collection_name_per_user';
    END IF;
END $$;

