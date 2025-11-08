# RSS Feed URLs for Sources

Here are the RSS feed URLs for your sources:

## ✅ Available RSS Feeds

### 1. **Wired**
- URL: `https://www.wired.com/feed/rss`
- Updates: Hourly
- Content: Tech, Science, Business, Culture

### 2. **TechCrunch**
- URL: `https://techcrunch.com/feed/`
- Updates: Every 15-30 minutes
- Content: Startups, Tech news, Venture Capital

### 3. **MIT Technology Review**
- URL: `https://www.technologyreview.com/feed/`
- Updates: Daily
- Content: Emerging tech, Science, Innovation

### 4. **The Guardian (Technology)**
- URL: `https://www.theguardian.com/technology/rss`
- Updates: Hourly
- Content: Tech news, Policy, Industry

### 5. **BBC Science & Environment**
- URL: `https://feeds.bbci.co.uk/news/science_and_environment/rss.xml`
- Updates: Hourly
- Content: Science, Climate, Environment

### 6. **Ars Technica**
- URL: `https://feeds.arstechnica.com/arstechnica/index`
- Updates: Hourly
- Content: Tech, Science, Policy, Gaming

### 7. **The Verge**
- URL: `https://www.theverge.com/rss/index.xml`
- Updates: Hourly
- Content: Tech, Science, Art, Culture

---

## 🔧 How to Auto-Fetch Articles

I've created a Supabase Edge Function that will:
1. ✅ Fetch articles from RSS feeds automatically
2. ✅ Filter by time (2h, 24h, 7d)
3. ✅ Only fetch from user's active sources
4. ✅ Extract topics automatically
5. ✅ Prevent duplicates
6. ✅ Add to database

---

## 📦 Setup Instructions

### Option 1: Deploy Supabase Edge Function (Automated)

1. **Install Supabase CLI**
```bash
brew install supabase/tap/supabase
```

2. **Login to Supabase**
```bash
supabase login
```

3. **Link to your project**
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
supabase link --project-ref YOUR_PROJECT_REF
```

4. **Deploy the function**
```bash
supabase functions deploy fetch-articles
```

5. **Set environment variables**
```bash
supabase secrets set SUPABASE_URL=your_url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_key
```

6. **Schedule it to run every hour** (in Supabase Dashboard)
   - Go to Database → Functions
   - Create a cron job:
   ```sql
   SELECT cron.schedule(
     'fetch-articles-hourly',
     '0 * * * *',  -- Every hour
     $$
     SELECT net.http_post(
       url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-articles',
       headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
       body:='{"timeFilter": "24h", "userId": "YOUR_USER_ID"}'::jsonb
     );
     $$
   );
   ```

---

### Option 2: Manual Fetch (Quick Test)

Use this SQL to manually test RSS feed fetching:

```sql
-- This will call the edge function manually
SELECT net.http_post(
  url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-articles',
  headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
  body:='{"timeFilter": "24h", "userId": "49e81c6e-cf9b-400d-a939-b1758..."}'::jsonb
);
```

---

### Option 3: Flutter Integration (Call from App)

I can also create a Flutter service to fetch articles on app startup:

```dart
// In feed_provider.dart
Future<void> fetchArticlesFromFeeds() async {
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return;

  final response = await http.post(
    Uri.parse('https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-articles'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
    },
    body: jsonEncode({
      'timeFilter': '24h',
      'userId': userId,
    }),
  );

  if (response.statusCode == 200) {
    // Refresh feed
    await loadArticles();
  }
}
```

---

## 🎯 What This Solves

### Before:
- ❌ Had to manually add articles via SQL
- ❌ No real-time updates
- ❌ No automatic fetching

### After:
- ✅ Automatically fetches from RSS feeds
- ✅ Filters by time (2h, 24h, 7d)
- ✅ Only fetches from active sources
- ✅ Prevents duplicates
- ✅ Runs hourly (or on-demand)

---

## 📊 Time Filters

The function supports three time filters:

1. **`2h`** - Last 2 hours (breaking news)
2. **`24h`** - Last 24 hours (daily digest)
3. **`7d`** - Last 7 days (weekly roundup)

---

## 🔄 How It Works

```
1. User adds source (e.g., "Ars Technica") → Saved to sources table
2. Edge Function runs (hourly or on-demand)
3. Function fetches RSS feed from arstechnica.com
4. Parses articles from last 24 hours
5. Extracts: title, summary, author, link, date
6. Checks for duplicates (by URL)
7. Inserts new articles into articles table
8. App refreshes feed → Shows new articles!
```

---

## 🚀 Quick Start

**Fastest way to get articles:**

1. Run the SQL I provided earlier (`add_sample_articles.sql`) - **5 minutes**
2. Deploy the Edge Function above - **10 minutes**
3. Set up hourly cron job - **5 minutes**

**Total time: ~20 minutes for fully automated article fetching!**

---

## ❓ FAQ

**Q: Do I need to pay for Edge Functions?**  
A: Supabase Free Tier includes 500K edge function invocations/month (plenty!)

**Q: Can I fetch more frequently than hourly?**  
A: Yes! Change cron to `*/30 * * * *` for every 30 minutes

**Q: What if an RSS feed is down?**  
A: Function handles errors gracefully and continues with other sources

**Q: Can I add more sources?**  
A: Yes! Just add the RSS feed URL to the `RSS_FEEDS` object in the function

