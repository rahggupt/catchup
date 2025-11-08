-- Add Sample Articles for Your Sources
-- Run this in Supabase SQL Editor to populate articles from your sources

-- Articles from Wired
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('AI Agents Are Coming to Transform Your Workplace', 
 'Autonomous AI agents are poised to revolutionize how we work, moving beyond simple chatbots to handle complex tasks.',
 'Wired', 'Lauren Goode', '#AI', 
 'https://wired.com/ai-agents-workplace',
 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
 NOW() - INTERVAL '2 hours'),

('The Race to Build Quantum Internet', 
 'Scientists are making progress on quantum networks that could revolutionize secure communication.',
 'Wired', 'Katrina Miller', '#Tech', 
 'https://wired.com/quantum-internet',
 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80',
 NOW() - INTERVAL '5 hours');

-- Articles from TechCrunch
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('Startup Raises $100M for AI-Powered Code Review', 
 'A new startup is using AI to automatically review code, catching bugs before they reach production.',
 'TechCrunch', 'Sarah Perez', '#AI', 
 'https://techcrunch.com/ai-code-review',
 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
 NOW() - INTERVAL '1 hour'),

('Electric Vehicle Sales Hit Record High', 
 'Global EV adoption continues to accelerate with record-breaking sales in Q4.',
 'TechCrunch', 'Kirsten Korosec', '#Climate', 
 'https://techcrunch.com/ev-sales-record',
 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800&q=80',
 NOW() - INTERVAL '3 hours');

-- Articles from MIT Tech Review
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('CRISPR Gene Therapy Shows Promise in Clinical Trials', 
 'New gene editing treatments are showing remarkable results in treating genetic diseases.',
 'MIT Tech Review', 'Antonio Regalado', '#Science', 
 'https://technologyreview.com/crispr-therapy',
 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=800&q=80',
 NOW() - INTERVAL '4 hours'),

('How AI is Revolutionizing Drug Discovery', 
 'Machine learning algorithms are dramatically speeding up the process of finding new medications.',
 'MIT Tech Review', 'Emily Mullin', '#AI', 
 'https://technologyreview.com/ai-drug-discovery',
 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800&q=80',
 NOW() - INTERVAL '6 hours');

-- Articles from The Guardian
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('UN Climate Summit Reaches Historic Agreement', 
 'World leaders commit to ambitious new climate targets at COP29.',
 'The Guardian', 'Fiona Harvey', '#Climate', 
 'https://theguardian.com/climate-summit',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
 NOW() - INTERVAL '7 hours'),

('Tech Giants Face New AI Regulation', 
 'European Union proposes comprehensive framework for AI governance.',
 'The Guardian', 'Dan Milmo', '#Politics', 
 'https://theguardian.com/ai-regulation',
 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80',
 NOW() - INTERVAL '8 hours');

-- Articles from BBC Science
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('Mars Rover Discovers Evidence of Ancient Water', 
 'NASA''s Perseverance rover finds compelling signs of past water on Mars.',
 'BBC Science', 'Jonathan Amos', '#Science', 
 'https://bbc.com/mars-water-discovery',
 'https://images.unsplash.com/photo-1614728423169-3f65fd722b7e?w=800&q=80',
 NOW() - INTERVAL '9 hours'),

('Breakthrough in Fusion Energy Research', 
 'Scientists achieve significant milestone in sustainable fusion power generation.',
 'BBC Science', 'Paul Rincon', '#Innovation', 
 'https://bbc.com/fusion-breakthrough',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
 NOW() - INTERVAL '10 hours');

-- Check results
SELECT source, COUNT(*) as article_count 
FROM articles 
GROUP BY source 
ORDER BY article_count DESC;

