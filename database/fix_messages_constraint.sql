-- Fix messages_role_check constraint error
-- This ensures the 'role' column in messages table accepts 'user', 'assistant', and 'system' values

-- Drop the existing constraint if it exists
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_role_check;

-- Add the correct constraint
ALTER TABLE messages ADD CONSTRAINT messages_role_check 
  CHECK (role IN ('user', 'assistant', 'system'));

-- Verify the constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'messages_role_check';

COMMENT ON CONSTRAINT messages_role_check ON messages IS 'Ensures message role is one of: user, assistant, system';

