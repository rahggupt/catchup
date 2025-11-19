# Database Validation Guide

## Purpose

This script validates that your database operations and RLS (Row Level Security) policies are working correctly **before** deploying the app.

## What It Tests

1. ✅ User authentication
2. ✅ Fetching user collections
3. ✅ Creating test article
4. ✅ Adding article to collection (RLS INSERT policy)
5. ✅ Fetching articles from collection (RLS SELECT policy)
6. ✅ Counting articles
7. ✅ Deleting article from collection (RLS DELETE policy)
8. ✅ Cleanup

---

## Prerequisites

1. **Sign in to the app first**
   - The test needs an authenticated user session
   - Open the app on your phone/emulator and sign in

2. **Ensure .env file exists**
   - Must contain valid Supabase credentials

---

## How to Run

### Method 1: Using the Script (Recommended)

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
./scripts/run_db_validation.sh
```

### Method 2: Direct Flutter Test

```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
flutter test test/database_validation_test.dart --reporter=expanded
```

---

## Understanding the Results

### ✅ All Tests Pass

```
✅ User authenticated: <user_id>
✅ Found 3 collections
✅ Test article created: <article_id>
✅ Article added to collection
✅ Verified: Article exists in collection_articles
✅ Found 1 article(s) in collection
✅ Test article found in collection!
✅ Collection has 1 article(s)
✅ Article deleted from collection
✅ Verified: Article removed from collection
```

**Meaning**: Your database and RLS policies are working correctly! Safe to deploy.

---

### ❌ Test Fails: "Error adding article to collection"

```
❌ Error adding article to collection: <error>
💡 This might be an RLS policy issue!
```

**Problem**: The INSERT RLS policy is missing or incorrect.

**Solution**: Run the SQL fix in Supabase:

```sql
CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);
```

---

### ❌ Test Fails: "Test article NOT found in collection"

```
❌ Test article NOT found in collection!
💡 This suggests an RLS SELECT policy issue!
```

**Problem**: The SELECT RLS policy is missing or incorrect.

**Solution**: Run the SQL fix in Supabase:

```sql
CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);
```

---

### ❌ Test Fails: "Article still exists in collection"

```
❌ Article still exists in collection!
💡 This suggests an RLS DELETE policy issue!
```

**Problem**: The DELETE RLS policy is missing or incorrect.

**Solution**: Run the SQL fix in Supabase:

```sql
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

---

### ❌ Test Fails: "No authenticated user"

```
❌ No authenticated user found
💡 Please sign in to the app first, then run this test
```

**Problem**: You're not signed in to the app.

**Solution**: 
1. Open the app on your phone/emulator
2. Sign in with your account
3. Run the test again

---

## Complete SQL Fix (Run All at Once)

If multiple tests fail, run this complete SQL fix in Supabase:

```sql
-- Enable RLS
ALTER TABLE collection_articles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "collection_articles_select" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_insert" ON collection_articles;
DROP POLICY IF EXISTS "collection_articles_delete" ON collection_articles;

-- SELECT: Users can view articles in their collections
CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);

-- INSERT: Users can add articles to their collections
CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- DELETE: Users can remove articles from their collections
CREATE POLICY "collection_articles_delete" ON collection_articles
FOR DELETE USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);

-- Verify policies created
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'collection_articles';
```

---

## Workflow

1. **Make changes** to your code or database
2. **Run validation script**: `./scripts/run_db_validation.sh`
3. **Check results**:
   - ✅ All pass? → Safe to deploy!
   - ❌ Any fail? → Fix the issue, run again
4. **Build & deploy** once all tests pass

---

## Troubleshooting

### Error: "connection refused"

Check your `.env` file has correct Supabase URL and keys.

### Error: "table does not exist"

Run database migrations in Supabase first.

### Error: "permission denied"

RLS policies are blocking the operation - apply the SQL fix.

---

## What the Test Does NOT Check

- UI rendering
- Performance
- Network issues
- App-specific business logic

This test **only validates database operations and RLS policies**.

---

## Next Steps After Validation

Once all tests pass:

1. Build APK: `./build_apk_java21.sh`
2. Install on device: `adb install build/app/outputs/flutter-apk/app-release.apk`
3. Test manually in the app
4. Deploy to production

---

**Good luck! 🚀**

