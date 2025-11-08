-- ========================================
-- FIX EVERYTHING - Run this ONE script
-- ========================================
-- This script will:
-- 1. Fix your stats (collections, articles counts)
-- 2. Add sample articles to your feed
-- 3. Set up auto-updating triggers
-- Run this in Supabase SQL Editor and ALL issues will be resolved!

-- =====================================
-- PART 1: FIX STATS IMMEDIATELY
-- =====================================

-- Update stats based on actual counts
UPDATE users u
SET stats = jsonb_build_object(
    'articles', (
        SELECT COUNT(DISTINCT ca.article_id)
        FROM collections c
        LEFT JOIN collection_articles ca ON c.id = ca.collection_id
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

-- =====================================
-- PART 2: ADD ARTICLES TO FEED
-- =====================================

-- Add 15 fresh articles from various sources
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES

-- Wired articles
('AI Agents Transform Enterprise Workflows',
 'New autonomous AI agents are revolutionizing how businesses operate, handling complex tasks end-to-end.',
 'Wired', 'Lauren Goode', '#AI',
 'https://wired.com/ai-agents-enterprise',
 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
 NOW() - INTERVAL '1 hour'),

('Quantum Computing Reaches Commercial Viability',
 'Major breakthrough in quantum error correction brings us closer to practical quantum computers.',
 'Wired', 'Katrina Miller', '#Tech',
 'https://wired.com/quantum-computing',
 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80',
 NOW() - INTERVAL '3 hours'),

-- TechCrunch articles
('Startup Raises $250M for AI Code Generation',
 'YC-backed startup lands massive round for AI that writes production-ready code.',
 'TechCrunch', 'Sarah Perez', '#AI',
 'https://techcrunch.com/ai-code-generation',
 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
 NOW() - INTERVAL '30 minutes'),

('EV Market Share Hits 15% in Q4',
 'Electric vehicle adoption accelerates as battery costs continue to plummet.',
 'TechCrunch', 'Kirsten Korosec', '#Climate',
 'https://techcrunch.com/ev-market-share',
 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800&q=80',
 NOW() - INTERVAL '2 hours'),

('OpenAI Announces GPT-5 with Video Generation',
 'Next-generation model can create high-quality video from text prompts.',
 'TechCrunch', 'Kyle Wiggers', '#AI',
 'https://techcrunch.com/gpt-5-video',
 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80',
 NOW() - INTERVAL '45 minutes'),

-- Ars Technica articles
('NASA Confirms Water Ice on Mars Equator',
 'Perseverance rover discovers accessible water ice deposits near the Martian equator.',
 'Ars Technica', 'Eric Berger', '#Science',
 'https://arstechnica.com/mars-water-ice',
 'https://images.unsplash.com/photo-1614728423169-3f65fd722b7e?w=800&q=80',
 NOW() - INTERVAL '4 hours'),

('New CPU Architecture Doubles Performance',
 'Revolutionary chiplet design breaks through performance barriers.',
 'Ars Technica', 'Jim Salter', '#Tech',
 'https://arstechnica.com/cpu-architecture',
 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
 NOW() - INTERVAL '5 hours'),

('Breakthrough in Room-Temperature Superconductors',
 'Scientists achieve superconductivity at near-ambient conditions.',
 'Ars Technica', 'John Timmer', '#Science',
 'https://arstechnica.com/superconductors',
 'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=800&q=80',
 NOW() - INTERVAL '3 hours 30 minutes'),

-- MIT Tech Review articles
('CRISPR Treatment Cures Genetic Disease',
 'First successful gene editing therapy eliminates inherited disorder.',
 'MIT Tech Review', 'Antonio Regalado', '#Science',
 'https://technologyreview.com/crispr-cure',
 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=800&q=80',
 NOW() - INTERVAL '6 hours'),

('AI Accelerates Drug Discovery by 100x',
 'Machine learning models identify promising drug candidates in days instead of years.',
 'MIT Tech Review', 'Emily Mullin', '#AI',
 'https://technologyreview.com/ai-drug-discovery',
 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800&q=80',
 NOW() - INTERVAL '7 hours'),

-- The Guardian articles
('UN Climate Summit Reaches Historic Agreement',
 'World leaders commit to net-zero emissions by 2040 in landmark deal.',
 'The Guardian', 'Fiona Harvey', '#Climate',
 'https://theguardian.com/climate-agreement',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
 NOW() - INTERVAL '8 hours'),

('EU Passes Comprehensive AI Regulation',
 'Sweeping legislation sets global standard for AI governance.',
 'The Guardian', 'Dan Milmo', '#Politics',
 'https://theguardian.com/eu-ai-regulation',
 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80',
 NOW() - INTERVAL '9 hours'),

-- BBC Science articles
('Fusion Reactor Achieves Net Energy Gain',
 'Historic milestone: fusion experiment produces more energy than consumed.',
 'BBC Science', 'Paul Rincon', '#Innovation',
 'https://bbc.com/fusion-breakthrough',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
 NOW() - INTERVAL '10 hours'),

('New Telescope Discovers Earth-Like Planet',
 'James Webb finds potentially habitable world just 31 light-years away.',
 'BBC Science', 'Jonathan Amos', '#Science',
 'https://bbc.com/exoplanet-discovery',
 'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4?w=800&q=80',
 NOW() - INTERVAL '11 hours'),

('AI Predicts Protein Structures with Perfect Accuracy',
 'DeepMind''s latest model solves 50-year biology challenge.',
 'BBC Science', 'Pallab Ghosh', '#AI',
 'https://bbc.com/protein-structure-ai',
 'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=800&q=80',
 NOW() - INTERVAL '12 hours');

-- =====================================
-- PART 3: CREATE AUTO-UPDATE TRIGGERS
-- =====================================

-- Function to auto-update stats when collections change
CREATE OR REPLACE FUNCTION update_user_stats_on_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the owner's stats
    UPDATE users
    SET stats = jsonb_build_object(
        'articles', (
            SELECT COUNT(DISTINCT ca.article_id)
            FROM collections c
            LEFT JOIN collection_articles ca ON c.id = ca.collection_id
            WHERE c.owner_id = COALESCE(NEW.owner_id, OLD.owner_id)
        ),
        'collections', (
            SELECT COUNT(*)
            FROM collections
            WHERE owner_id = COALESCE(NEW.owner_id, OLD.owner_id)
        ),
        'chats', (
            SELECT COUNT(*)
            FROM chats
            WHERE user_id = COALESCE(NEW.owner_id, OLD.owner_id)
        )
    )
    WHERE uid = COALESCE(NEW.owner_id, OLD.owner_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for collections
DROP TRIGGER IF EXISTS trigger_update_stats_on_collection ON collections;
CREATE TRIGGER trigger_update_stats_on_collection
    AFTER INSERT OR DELETE ON collections
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats_on_collection();

-- Function to auto-update stats when articles are added/removed
CREATE OR REPLACE FUNCTION update_user_stats_on_article()
RETURNS TRIGGER AS $$
DECLARE
    owner_user_id UUID;
BEGIN
    -- Get the owner of the collection
    SELECT owner_id INTO owner_user_id
    FROM collections
    WHERE id = COALESCE(NEW.collection_id, OLD.collection_id);
    
    -- Update the owner's stats
    IF owner_user_id IS NOT NULL THEN
        UPDATE users
        SET stats = jsonb_build_object(
            'articles', (
                SELECT COUNT(DISTINCT ca.article_id)
                FROM collections c
                LEFT JOIN collection_articles ca ON c.id = ca.collection_id
                WHERE c.owner_id = owner_user_id
            ),
            'collections', (
                SELECT COUNT(*)
                FROM collections
                WHERE owner_id = owner_user_id
            ),
            'chats', (
                SELECT COUNT(*)
                FROM chats
                WHERE user_id = owner_user_id
            )
        )
        WHERE uid = owner_user_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for collection_articles
DROP TRIGGER IF EXISTS trigger_update_stats_on_article ON collection_articles;
CREATE TRIGGER trigger_update_stats_on_article
    AFTER INSERT OR DELETE ON collection_articles
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats_on_article();

-- =====================================
-- PART 4: VERIFY EVERYTHING
-- =====================================

-- Check articles were added
SELECT 
    source,
    COUNT(*) as article_count
FROM articles
GROUP BY source
ORDER BY article_count DESC;

-- Check your stats are correct
SELECT 
    email,
    first_name,
    stats->'articles' as articles_stat,
    stats->'collections' as collections_stat,
    (SELECT COUNT(*) FROM collections WHERE owner_id = users.uid) as actual_collections,
    (SELECT COUNT(DISTINCT ca.article_id) 
     FROM collections c 
     LEFT JOIN collection_articles ca ON c.id = ca.collection_id 
     WHERE c.owner_id = users.uid) as actual_articles
FROM users;

-- Show recent articles
SELECT 
    title,
    source,
    topic,
    AGE(NOW(), published_at) as age
FROM articles
ORDER BY published_at DESC
LIMIT 10;

-- Success message
SELECT 
    '✅ SUCCESS! Your feed now has ' || COUNT(*) || ' articles!' as status,
    'Refresh your app to see them!' as action
FROM articles;

