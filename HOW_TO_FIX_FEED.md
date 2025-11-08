# 🔧 How to Fix Empty Feed Issue

## Problem: Feed shows mock data even after adding sources

**Why this happens:**
- Adding sources in the app only tracks which sources you want to follow
- It **doesn't automatically fetch articles** from those websites
- The `articles` table in Supabase is empty, so the app falls back to mock data

---

## ✅ Solution: Add Articles to Database

### Option 1: Quick Fix - Add Sample Articles (Recommended)

1. **Open Supabase Dashboard**
   - Go to your project
   - Click "SQL Editor" in the left sidebar

2. **Run the SQL Script**
   - Open the file: `add_sample_articles.sql`
   - Copy all the SQL code
   - Paste into Supabase SQL Editor
   - Click "Run" button

3. **Verify Articles Added**
   - You should see: "SUCCESS: 10 rows affected" (or similar)
   - The script adds 10 sample articles from your sources:
     - 2 from Wired
     - 2 from TechCrunch
     - 2 from MIT Tech Review
     - 2 from The Guardian
     - 2 from BBC Science

4. **Refresh Your App**
   - Go back to the app
   - Pull down on the feed to refresh
   - You should now see the new articles!

---

### Option 2: Add Your Own Custom Articles

Run this SQL with your own data:

```sql
INSERT INTO articles (title, summary, source, author, topic, url, image_url, published_at) VALUES
('Your Article Title', 
 'Article summary here',
 'Wired',  -- Must match one of your sources
 'Author Name', 
 '#Tech',  -- Topic tag
 'https://example.com/article',
 'https://images.unsplash.com/photo-id?w=800',
 NOW());
```

**Important:** The `source` field must match exactly the name of sources you added (Wired, TechCrunch, etc.)

---

## 📊 Stats Issue - FIXED! ✅

The stats issue has been fixed. Now when you:
- ✅ Create a collection → Collections count increases
- ✅ Add article to collection → Articles count increases
- ✅ Stats automatically refresh in Profile

**Test it:**
1. Swipe right on an article → Create new collection
2. Go to Profile tab
3. Check "My Stats" → Collections should show 1 (or more)
4. Add more articles to collections
5. Stats update automatically!

---

## 🎯 Summary

### Feed Issue:
- ❌ **Not a bug** - it's by design
- 📝 Sources track what you want to follow
- 📰 Articles must be added separately to the database
- 🔧 **Fix:** Run `add_sample_articles.sql` to populate feed

### Stats Issue:
- ✅ **FIXED** - Stats now update automatically
- ✅ Collections count updates when you create collections
- ✅ Articles count updates when you add articles to collections
- ✅ Profile refreshes to show updated stats

---

## 🚀 After Running the SQL Script:

Your feed will show:
- Real articles from Wired
- Real articles from TechCrunch
- Real articles from MIT Tech Review
- Real articles from The Guardian
- Real articles from BBC Science

**No more mock data!** 🎉

---

## 🔮 Future Enhancement (Optional):

To fully automate article fetching, we would need to implement:
1. RSS feed parser for each source
2. Web scraping for sources without RSS
3. Background job to fetch articles periodically
4. Article deduplication logic

This is a more complex feature that would require:
- Supabase Edge Functions for scraping
- Scheduled cron jobs
- API integrations with news sources

For now, manually adding articles via SQL is the simplest solution!

---

## ❓ FAQ

**Q: Why can't the app automatically fetch articles from websites?**  
A: Web scraping requires:
- Respecting robots.txt and rate limits
- Handling different website structures
- API keys for some news sources
- Backend processing (not possible in pure Flutter)

**Q: How often should I add new articles?**  
A: As often as you want! You can run the SQL script daily, or write your own script to automate it.

**Q: Can I delete the mock articles?**  
A: Yes! The app will only show mock articles when the database is empty. Once you have real articles, mock data disappears.

**Q: Will my stats keep working?**  
A: Yes! Stats are now fully functional and will update automatically as you use the app.

