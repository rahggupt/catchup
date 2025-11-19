-- AI Chat Tables Schema
-- Run this in Supabase SQL Editor after running collection_sharing_schema.sql

-- ========================================
-- 1. CHATS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE SET NULL,
  title TEXT DEFAULT 'New Chat',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_chats_user ON chats(user_id);
CREATE INDEX IF NOT EXISTS idx_chats_collection ON chats(collection_id);
CREATE INDEX IF NOT EXISTS idx_chats_updated ON chats(updated_at DESC);

-- ========================================
-- 2. MESSAGES TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);

-- ========================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ========================================

-- Enable RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Chats Policies
DROP POLICY IF EXISTS "users_view_own_chats" ON chats;
CREATE POLICY "users_view_own_chats" ON chats
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_create_chats" ON chats;
CREATE POLICY "users_create_chats" ON chats
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_update_own_chats" ON chats;
CREATE POLICY "users_update_own_chats" ON chats
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_delete_own_chats" ON chats;
CREATE POLICY "users_delete_own_chats" ON chats
  FOR DELETE
  USING (auth.uid() = user_id);

-- Messages Policies
DROP POLICY IF EXISTS "users_view_chat_messages" ON messages;
CREATE POLICY "users_view_chat_messages" ON messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = messages.chat_id
      AND chats.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "users_create_messages" ON messages;
CREATE POLICY "users_create_messages" ON messages
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = messages.chat_id
      AND chats.user_id = auth.uid()
    )
  );

-- ========================================
-- 4. REALTIME SUBSCRIPTION
-- ========================================

-- Enable Realtime for messages (for real-time chat updates)
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;

-- ========================================
-- 5. ALTER EXISTING TABLES (if needed)
-- ========================================

-- Add created_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chats' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE chats ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
    RAISE NOTICE 'Added created_at column to chats table';
  END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chats' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE chats ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
    RAISE NOTICE 'Added updated_at column to chats table';
  END IF;
END $$;

-- Add created_at column to messages if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE messages ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
    RAISE NOTICE 'Added created_at column to messages table';
  END IF;
END $$;

-- ========================================
-- 6. TRIGGERS
-- ========================================

-- Update chat's updated_at when message is added
CREATE OR REPLACE FUNCTION update_chat_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chats
  SET updated_at = NOW()
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_chat_on_message ON messages;
CREATE TRIGGER update_chat_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_timestamp();

-- ========================================
-- 7. COMMENTS
-- ========================================

COMMENT ON TABLE chats IS 'AI chat sessions linked to users and optionally to collections';
COMMENT ON TABLE messages IS 'Individual messages in chat sessions (user or AI)';
COMMENT ON COLUMN chats.collection_id IS 'Optional: if specified, AI uses RAG from this collection';
COMMENT ON COLUMN messages.role IS 'Either "user" or "assistant" (AI)';

-- ========================================
-- COMPLETE! 🎉
-- ========================================

-- Verify tables were created
SELECT 
  'chats' as table_name, 
  COUNT(*) as row_count 
FROM chats
UNION ALL
SELECT 
  'messages' as table_name, 
  COUNT(*) as row_count 
FROM messages;

-- Show success message
DO $$
BEGIN
  RAISE NOTICE '✅ Chat tables created successfully!';
  RAISE NOTICE '📊 Tables: chats, messages';
  RAISE NOTICE '🔒 RLS policies enabled';
  RAISE NOTICE '⚡ Realtime enabled for live chat';
  RAISE NOTICE '🚀 Ready for AI Chat!';
END $$;

