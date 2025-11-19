# Quick Install Guide - Article Saving Fix

## What's Fixed ✅

1. **Articles not appearing in collections** - Fixed RLS policies
2. **Perplexity API error** - Fixed model name 
3. **Share link crashes** - Fixed substring range error

## 2-Step Installation

### Step 1: Run SQL in Supabase (2 minutes)

Go to: https://app.supabase.com/project/YOUR_PROJECT/sql

Copy and run:

```sql
-- Fix RLS Policies for collection_articles Table
ALTER TABLE collection_articles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "collection_articles_select" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_insert" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_delete" ON collection_articles;

CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);

CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

CREATE POLICY "collection_articles_delete" ON collection_articles
FOR DELETE USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);
```

### Step 2: Install New APK

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Test It Works

1. **Add article** - Swipe right on any article, add to collection
2. **Check Collections tab** - Should show "1 articles" (not "0")
3. **Perplexity AI** - Should work without model error
4. **Share collection** - Should work without crash

## Done! 🎉

For detailed info, see `ARTICLE_SAVING_FIX.md`

