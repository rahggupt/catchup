-- Collection Sharing & Privacy System
-- Run this SQL in your Supabase SQL Editor

-- 1. Create collection_members table
CREATE TABLE IF NOT EXISTS collection_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  invited_by UUID REFERENCES auth.users(id),
  UNIQUE(collection_id, user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_collection_members_collection ON collection_members(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_members_user ON collection_members(user_id);

-- 2. Create collection_invites table
CREATE TABLE IF NOT EXISTS collection_invites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_collection_invites_collection ON collection_invites(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_invites_email ON collection_invites(invitee_email);
CREATE INDEX IF NOT EXISTS idx_collection_invites_status ON collection_invites(status);

-- 3. Update collections table to add sharing fields
ALTER TABLE collections 
  ADD COLUMN IF NOT EXISTS shareable_token TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS share_enabled BOOLEAN DEFAULT FALSE;

-- Index for fast token lookups
CREATE INDEX IF NOT EXISTS idx_collections_shareable_token ON collections(shareable_token) WHERE shareable_token IS NOT NULL;

-- 4. RLS Policies for collection_members
ALTER TABLE collection_members ENABLE ROW LEVEL SECURITY;

-- Users can view their own memberships
CREATE POLICY "users_view_own_memberships" ON collection_members
  FOR SELECT
  USING (auth.uid() = user_id);

-- Collection owners can view all members
CREATE POLICY "owners_view_all_members" ON collection_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM collections c
      WHERE c.id = collection_members.collection_id
      AND c.owner_id = auth.uid()
    )
  );

-- Collection owners can manage members
CREATE POLICY "owners_manage_members" ON collection_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM collections c
      WHERE c.id = collection_members.collection_id
      AND c.owner_id = auth.uid()
    )
  );

-- 5. RLS Policies for collection_invites
ALTER TABLE collection_invites ENABLE ROW LEVEL SECURITY;

-- Users can view invites sent to them
CREATE POLICY "users_view_own_invites" ON collection_invites
  FOR SELECT
  USING (invitee_email = auth.jwt()->>'email');

-- Collection owners can view all invites for their collections
CREATE POLICY "owners_view_invites" ON collection_invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM collections c
      WHERE c.id = collection_invites.collection_id
      AND c.owner_id = auth.uid()
    )
  );

-- Collection owners can manage invites
CREATE POLICY "owners_manage_invites" ON collection_invites
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM collections c
      WHERE c.id = collection_invites.collection_id
      AND c.owner_id = auth.uid()
    )
  );

-- 6. Update existing collection RLS policies
DROP POLICY IF EXISTS "collection_access" ON collections;

CREATE POLICY "collection_access" ON collections
  FOR SELECT
  USING (
    -- User owns the collection
    auth.uid() = owner_id 
    OR
    -- User is a member of the collection
    EXISTS (
      SELECT 1 FROM collection_members cm
      WHERE cm.collection_id = collections.id
      AND cm.user_id = auth.uid()
    )
    OR
    -- Collection has public sharing enabled
    (privacy = 'public' AND share_enabled = TRUE)
  );

-- 7. Update collection_articles RLS policy
DROP POLICY IF EXISTS "collection_articles_access" ON collection_articles;

CREATE POLICY "collection_articles_access" ON collection_articles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM collections c
      WHERE c.id = collection_articles.collection_id
      AND (
        -- User owns the collection
        c.owner_id = auth.uid() 
        OR
        -- User is a member
        EXISTS (
          SELECT 1 FROM collection_members cm
          WHERE cm.collection_id = c.id
          AND cm.user_id = auth.uid()
        )
        OR
        -- Collection is public and sharing is enabled
        (c.privacy = 'public' AND c.share_enabled = TRUE)
      )
    )
  );

-- 8. Function to generate unique shareable token
CREATE OR REPLACE FUNCTION generate_shareable_token()
RETURNS TEXT AS $$
DECLARE
  token TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    -- Generate a random 32-character token
    token := encode(gen_random_bytes(24), 'base64');
    -- Remove characters that might cause URL issues
    token := replace(replace(replace(token, '/', '_'), '+', '-'), '=', '');
    
    -- Check if token already exists
    SELECT EXISTS(SELECT 1 FROM collections WHERE shareable_token = token) INTO exists;
    EXIT WHEN NOT exists;
  END LOOP;
  
  RETURN token;
END;
$$ LANGUAGE plpgsql;

-- 9. Function to accept invite
CREATE OR REPLACE FUNCTION accept_collection_invite(invite_id UUID)
RETURNS VOID AS $$
DECLARE
  invite_record RECORD;
BEGIN
  -- Get invite details
  SELECT * INTO invite_record 
  FROM collection_invites 
  WHERE id = invite_id 
  AND invitee_email = auth.jwt()->>'email'
  AND status = 'pending';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found or already processed';
  END IF;
  
  -- Check if invite has expired
  IF invite_record.expires_at IS NOT NULL AND invite_record.expires_at < NOW() THEN
    RAISE EXCEPTION 'Invite has expired';
  END IF;
  
  -- Add user to collection_members
  INSERT INTO collection_members (collection_id, user_id, role, invited_by)
  VALUES (invite_record.collection_id, auth.uid(), 'viewer', invite_record.inviter_id)
  ON CONFLICT (collection_id, user_id) DO NOTHING;
  
  -- Update invite status
  UPDATE collection_invites
  SET status = 'accepted'
  WHERE id = invite_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE collection_members IS 'Tracks users who have access to collections (members, editors, viewers)';
COMMENT ON TABLE collection_invites IS 'Tracks pending/accepted/rejected invitations to collections';
COMMENT ON FUNCTION generate_shareable_token IS 'Generates a unique token for shareable collections';
COMMENT ON FUNCTION accept_collection_invite IS 'Accepts a collection invite and adds user as member';

