-- Fix Stats Issues
-- Run this in Supabase SQL Editor

-- 1. First, let's check current stats
SELECT 
    uid,
    email,
    first_name,
    stats
FROM users;

-- 2. Update stats based on actual counts
UPDATE users u
SET stats = jsonb_build_object(
    'articles', (
        SELECT COUNT(DISTINCT ca.article_id)
        FROM collections c
        JOIN collection_articles ca ON c.id = ca.collection_id
        WHERE c.owner_id = u.uid
    ),
    'collections', (
        SELECT COUNT(*)
        FROM collections
        WHERE owner_id = u.uid
    ),
    'chats', (
        SELECT COUNT(*)
        FROM chats
        WHERE user_id = u.uid
    )
);

-- 3. Verify the update
SELECT 
    uid,
    email,
    first_name,
    stats->'articles' as articles_count,
    stats->'collections' as collections_count,
    stats->'chats' as chats_count
FROM users;

-- 4. Create a function to auto-update stats
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the owner's stats
    UPDATE users
    SET stats = jsonb_build_object(
        'articles', (
            SELECT COUNT(DISTINCT ca.article_id)
            FROM collections c
            JOIN collection_articles ca ON c.id = ca.collection_id
            WHERE c.owner_id = NEW.owner_id
        ),
        'collections', (
            SELECT COUNT(*)
            FROM collections
            WHERE owner_id = NEW.owner_id
        ),
        'chats', (
            SELECT COUNT(*)
            FROM chats
            WHERE user_id = NEW.owner_id
        )
    )
    WHERE uid = NEW.owner_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for collections
DROP TRIGGER IF EXISTS trigger_update_stats_on_collection ON collections;
CREATE TRIGGER trigger_update_stats_on_collection
    AFTER INSERT OR DELETE ON collections
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats();

-- 6. Create function for article additions
CREATE OR REPLACE FUNCTION update_user_stats_on_article()
RETURNS TRIGGER AS $$
BEGIN
    -- Update stats for the user who added the article
    UPDATE users
    SET stats = jsonb_build_object(
        'articles', (
            SELECT COUNT(DISTINCT ca.article_id)
            FROM collections c
            JOIN collection_articles ca ON c.id = ca.collection_id
            WHERE c.owner_id = (
                SELECT owner_id FROM collections WHERE id = NEW.collection_id
            )
        ),
        'collections', (
            SELECT COUNT(*)
            FROM collections
            WHERE owner_id = (
                SELECT owner_id FROM collections WHERE id = NEW.collection_id
            )
        ),
        'chats', (
            SELECT COUNT(*)
            FROM chats
            WHERE user_id = (
                SELECT owner_id FROM collections WHERE id = NEW.collection_id
            )
        )
    )
    WHERE uid = (SELECT owner_id FROM collections WHERE id = NEW.collection_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger for collection_articles
DROP TRIGGER IF EXISTS trigger_update_stats_on_article ON collection_articles;
CREATE TRIGGER trigger_update_stats_on_article
    AFTER INSERT OR DELETE ON collection_articles
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats_on_article();

-- 8. Verify triggers are created
SELECT 
    trigger_name, 
    event_object_table, 
    action_statement 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%stats%';

-- 9. Final verification - check your actual data
SELECT 
    u.email,
    u.first_name,
    u.stats,
    (SELECT COUNT(*) FROM collections WHERE owner_id = u.uid) as actual_collections,
    (SELECT COUNT(DISTINCT ca.article_id) 
     FROM collections c 
     JOIN collection_articles ca ON c.id = ca.collection_id 
     WHERE c.owner_id = u.uid) as actual_articles
FROM users u;

