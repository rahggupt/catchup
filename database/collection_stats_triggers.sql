-- Collection Stats Triggers
-- Automatically update collection statistics when articles, chats, or members change

-- Function to recalculate collection stats
CREATE OR REPLACE FUNCTION recalculate_collection_stats(collection_id_param UUID)
RETURNS void AS $$
DECLARE
  article_cnt INTEGER;
  chat_cnt INTEGER;
  contributor_cnt INTEGER;
BEGIN
  -- Count articles in collection
  SELECT COUNT(DISTINCT article_id)
  INTO article_cnt
  FROM collection_articles
  WHERE collection_id = collection_id_param;
  
  -- Count chats for collection
  SELECT COUNT(*)
  INTO chat_cnt
  FROM chats
  WHERE collection_id = collection_id_param;
  
  -- Count contributors (owner + members)
  SELECT COUNT(DISTINCT user_id) + 1
  INTO contributor_cnt
  FROM collection_members
  WHERE collection_id = collection_id_param;
  
  -- Update collection stats
  UPDATE collections
  SET 
    stats = jsonb_build_object(
      'article_count', COALESCE(article_cnt, 0),
      'chat_count', COALESCE(chat_cnt, 0),
      'contributor_count', COALESCE(contributor_cnt, 1)
    ),
    updated_at = NOW()
  WHERE id = collection_id_param;
  
END;
$$ LANGUAGE plpgsql;

-- Trigger function for collection_articles changes
CREATE OR REPLACE FUNCTION trigger_update_collection_stats_on_article()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM recalculate_collection_stats(OLD.collection_id);
    RETURN OLD;
  ELSE
    PERFORM recalculate_collection_stats(NEW.collection_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for chats changes
CREATE OR REPLACE FUNCTION trigger_update_collection_stats_on_chat()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    IF OLD.collection_id IS NOT NULL THEN
      PERFORM recalculate_collection_stats(OLD.collection_id);
    END IF;
    RETURN OLD;
  ELSE
    IF NEW.collection_id IS NOT NULL THEN
      PERFORM recalculate_collection_stats(NEW.collection_id);
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for collection_members changes
CREATE OR REPLACE FUNCTION trigger_update_collection_stats_on_member()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM recalculate_collection_stats(OLD.collection_id);
    RETURN OLD;
  ELSE
    PERFORM recalculate_collection_stats(NEW.collection_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS collection_articles_stats_trigger ON collection_articles;
DROP TRIGGER IF EXISTS chats_stats_trigger ON chats;
DROP TRIGGER IF EXISTS collection_members_stats_trigger ON collection_members;

-- Create triggers for collection_articles
CREATE TRIGGER collection_articles_stats_trigger
AFTER INSERT OR DELETE ON collection_articles
FOR EACH ROW
EXECUTE FUNCTION trigger_update_collection_stats_on_article();

-- Create triggers for chats
CREATE TRIGGER chats_stats_trigger
AFTER INSERT OR DELETE ON chats
FOR EACH ROW
EXECUTE FUNCTION trigger_update_collection_stats_on_chat();

-- Create triggers for collection_members
CREATE TRIGGER collection_members_stats_trigger
AFTER INSERT OR DELETE ON collection_members
FOR EACH ROW
EXECUTE FUNCTION trigger_update_collection_stats_on_member();

-- Recalculate stats for all existing collections
DO $$
DECLARE
  collection_record RECORD;
BEGIN
  FOR collection_record IN SELECT id FROM collections
  LOOP
    PERFORM recalculate_collection_stats(collection_record.id);
  END LOOP;
  
  RAISE NOTICE 'Collection stats recalculated for all collections';
END $$;

