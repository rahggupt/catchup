#!/bin/bash

# Seed sample articles into Supabase database
# Run this AFTER you've signed up in the app

echo "This script will seed sample articles into your Supabase database"
echo "Make sure you've:"
echo "1. Created the database tables (run SQL from SETUP.md)"
echo "2. Signed up at least one user in the app"
echo ""
echo "To seed data, go to your Supabase SQL Editor and run:"
echo ""
cat << 'EOF'
-- Seed Sample Articles
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('The Future of AI: What Experts Predict for 2025', 
 'Leading AI researchers discuss groundbreaking developments expected this year, including advances in multimodal models and AI safety protocols.',
 'Wired', 'Sarah Chen', '#AI', 
 'https://wired.com/future-of-ai',
 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
 NOW() - INTERVAL '2 hours'),

('Climate Tech Startups Raise Record $50B in Funding',
 'Venture capital investment in climate technology reached unprecedented levels, with carbon capture and renewable energy leading the charge.',
 'MIT Tech Review', 'Alex Kumar', '#Climate',
 'https://technologyreview.com/climate-tech',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
 NOW() - INTERVAL '5 hours'),

('New Quantum Computing Breakthrough Achieves Error Correction',
 'Scientists have demonstrated a quantum computer that can correct its own errors in real-time, a crucial step toward practical quantum computing.',
 'BBC Science', 'Dr. James Wong', '#Tech',
 'https://bbc.com/science/quantum',
 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80',
 NOW() - INTERVAL '1 day');
EOF

echo ""
echo "Copy the SQL above and run it in Supabase SQL Editor!"

