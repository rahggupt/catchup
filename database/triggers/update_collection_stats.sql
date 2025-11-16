-- Auto-update collection stats when articles are added/removed
-- Run this SQL in your Supabase SQL Editor

-- Function to recalculate stats for a specific collection
CREATE OR REPLACE FUNCTION recalculate_collection_stats(coll_id UUID)
RETURNS VOID AS $$
DECLARE
  article_cnt INT;
  chat_cnt INT;
  contributor_cnt INT;
BEGIN
  -- Count articles in this collection
  SELECT COUNT(DISTINCT article_id)
  INTO article_cnt
  FROM collection_articles
  WHERE collection_id = coll_id;
  
  -- Count chats for this collection
  SELECT COUNT(*)
  INTO chat_cnt
  FROM chats
  WHERE collection_id = coll_id;
  
  -- Count unique contributors (users who added articles)
  SELECT COUNT(DISTINCT added_by)
  INTO contributor_cnt
  FROM collection_articles
  WHERE collection_id = coll_id;
  
  -- If no contributors, set to 1 (the owner)
  IF contributor_cnt = 0 THEN
    contributor_cnt := 1;
  END IF;
  
  -- Update the stats JSONB field
  UPDATE collections
  SET stats = jsonb_build_object(
    'article_count', article_cnt,
    'chat_count', chat_cnt,
    'contributor_count', contributor_cnt
  )
  WHERE id = coll_id;
  
  RAISE NOTICE 'Updated stats for collection %: articles=%, chats=%, contributors=%', 
    coll_id, article_cnt, chat_cnt, contributor_cnt;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for when articles are added
CREATE OR REPLACE FUNCTION trigger_update_collection_stats_on_article()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT or UPDATE
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    PERFORM recalculate_collection_stats(NEW.collection_id);
    RETURN NEW;
  -- For DELETE
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM recalculate_collection_stats(OLD.collection_id);
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for when chats are added/removed
CREATE OR REPLACE FUNCTION trigger_update_collection_stats_on_chat()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT or UPDATE
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    IF NEW.collection_id IS NOT NULL THEN
      PERFORM recalculate_collection_stats(NEW.collection_id);
    END IF;
    RETURN NEW;
  -- For DELETE
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.collection_id IS NOT NULL THEN
      PERFORM recalculate_collection_stats(OLD.collection_id);
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_stats_on_article_change ON collection_articles;
DROP TRIGGER IF EXISTS update_stats_on_chat_change ON chats;

-- Create triggers
CREATE TRIGGER update_stats_on_article_change
  AFTER INSERT OR UPDATE OR DELETE ON collection_articles
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_collection_stats_on_article();

CREATE TRIGGER update_stats_on_chat_change
  AFTER INSERT OR UPDATE OR DELETE ON chats
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_collection_stats_on_chat();

-- Recalculate stats for all existing collections
DO $$
DECLARE
  coll RECORD;
BEGIN
  FOR coll IN SELECT id FROM collections LOOP
    PERFORM recalculate_collection_stats(coll.id);
  END LOOP;
  RAISE NOTICE 'Recalculated stats for all collections';
END $$;

COMMENT ON FUNCTION recalculate_collection_stats IS 'Recalculates and updates stats for a specific collection';
COMMENT ON FUNCTION trigger_update_collection_stats_on_article IS 'Trigger function to update collection stats when articles change';
COMMENT ON FUNCTION trigger_update_collection_stats_on_chat IS 'Trigger function to update collection stats when chats change';

