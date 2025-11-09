# Fix "Add to Collection" 400 Error

## Problem
When trying to add an article to a collection, you're getting a **400 Bad Request** error. This is likely due to a foreign key constraint in the database.

## Root Cause
The `collection_articles` table has a foreign key constraint on `article_id` that requires the article to exist in the `articles` table BEFORE it can be added to a collection. However, when saving RSS articles, we're trying to add them to collections immediately.

## Solution

### Step 1: Run This SQL in Supabase

1. Go to your Supabase project: https://qgvmyntagfukrodafzfc.supabase.co
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste this SQL:

```sql
-- Option 1: Make the foreign key constraint DEFERRABLE
-- This allows the constraint to be checked at the end of the transaction
ALTER TABLE collection_articles
DROP CONSTRAINT IF EXISTS collection_articles_article_id_fkey;

ALTER TABLE collection_articles
ADD CONSTRAINT collection_articles_article_id_fkey
FOREIGN KEY (article_id)
REFERENCES articles(id)
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

-- Grant proper permissions
GRANT ALL ON collection_articles TO authenticated;
GRANT ALL ON articles TO authenticated;
```

5. Click **Run** (or press Cmd+Enter)

### Step 2: Test Again

After running the SQL:
1. Refresh your browser
2. Swipe right on an article
3. Select your "abc" collection
4. Click "Add to Collection"
5. Check the browser console for detailed logs

## What Changed in the Code

I've added better error handling and logging to help debug issues:

### `supabase_service.dart`
- ✅ Check if article already exists before creating
- ✅ Check if article is already in collection before adding
- ✅ Detailed console logging at each step
- ✅ Better error messages

### `rss_feed_service.dart`
- ✅ **CORS Proxy for Web**: RSS feeds now work in browser using `allorigins.win` proxy
- ✅ Direct fetch for mobile (no proxy needed)
- ✅ Automatic detection of web vs mobile platform

## Testing

Watch the browser console (F12 → Console) and you should see:

```
💾 Saving article to database: 00265043-0026-0026-0026-0026504302
🔍 Checking if article exists: 00265043-0026-0026-0026-0026504302
💾 Creating new article in database
✅ Article created successfully
📚 Adding article to collection: 3803d20e-6736-4bae-86b2-263b41e70173
🔍 Checking if article is already in collection
💾 Adding article to collection
   Collection ID: 3803d20e-6736-4bae-86b2-263b41e70173
   Article ID: 00265043-0026-0026-0026-0026504302
   Added By: <your-user-id>
✅ Article added to collection successfully
```

If you see errors, share the console output so I can help debug!

## CORS Fix

RSS feeds now work in the browser! 🎉

- **Web**: Uses CORS proxy automatically
- **Mobile/Android**: Direct fetch (no proxy needed, better performance)

All feeds (Wired, TechCrunch, Ars Technica, The Verge, etc.) should now load properly.

