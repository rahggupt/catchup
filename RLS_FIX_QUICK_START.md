# 🚀 Quick Start: Fix RLS Infinite Recursion

## The Problem

Your collections table has **9 RLS policies** (should only have 4):
- 3 SELECT policies → causing recursion
- 2 INSERT policies → duplicates
- 2 UPDATE policies → duplicates  
- 2 DELETE policies → duplicates

**Result:** `PostgrestException: infinite recursion detected (code: 42P17)`

---

## The Solution (2 Minutes)

### ⚠️ ERROR PERSISTS? Use Nuclear Option

If you already ran a fix and still get the recursion error:

1. Open **Supabase SQL Editor**
2. Copy entire file: `database/NUCLEAR_RLS_FIX.sql`
3. Paste and click **Run** ▶️
4. Restart Flutter app

This aggressively removes ALL policies (even hidden ones) and recreates them fresh.

---

### Option 1: Run Everything at Once ⚡ **RECOMMENDED**

1. Open **Supabase SQL Editor**
2. Copy entire file: `database/RUN_ALL_FIXES.sql`
3. Paste and click **Run** ▶️
4. Restart Flutter app

### Option 2: Run Collections Fix Only

1. Open **Supabase SQL Editor**
2. Copy entire file: `database/COMPLETE_RLS_FIX.sql`
3. Paste and click **Run** ▶️
4. Restart Flutter app

### Option 3: Diagnose First

1. Open **Supabase SQL Editor**
2. Copy entire file: `database/DIAGNOSE_RLS_ISSUE.sql`
3. Paste and click **Run** ▶️
4. Check the output to see which policies are problematic
5. Then run `NUCLEAR_RLS_FIX.sql`

---

## Verify It Worked

Run this in Supabase SQL Editor:

```sql
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'collections';
```

**Expected:** Returns `4` (not 9!)

---

## What This Does

### Before:
```
9 policies (duplicates + conflicts)
├── Users can view own and shared collections (SELECT) ← recursion!
├── Users can view their own collections (SELECT)
├── collection_access (SELECT)
├── Users can create collections (INSERT)
├── Users can insert collections (INSERT) ← duplicate
├── Users can update own collections (UPDATE)
├── Users can update their own collections (UPDATE) ← duplicate
├── Users can delete own collections (DELETE)
└── Users can delete their own collections (DELETE) ← duplicate
```

### After:
```
4 policies (clean + simple)
├── collections_select_policy (SELECT)
├── collections_insert_policy (INSERT)
├── collections_update_policy (UPDATE)
└── collections_delete_policy (DELETE)
```

---

## Test After Fix

✅ Feed screen loads without errors  
✅ Collections are visible  
✅ Can create new collections  
✅ Can save articles to collections  

---

## Files Changed

**SQL Scripts:**
- `database/COMPLETE_RLS_FIX.sql` - New comprehensive fix
- `database/RUN_ALL_FIXES.sql` - Updated with comprehensive fix
- `database/fix_collections_rls.sql` - Old (use COMPLETE version instead)

**Documentation:**
- `URGENT_FIXES.md` - Updated with duplicate policy explanation

---

## If It Still Fails

Check policy names match exactly:

```sql
SELECT policyname FROM pg_policies WHERE tablename = 'collections' ORDER BY policyname;
```

Should show:
1. `collections_delete_policy`
2. `collections_insert_policy`
3. `collections_select_policy`
4. `collections_update_policy`

If you see old names or 9 policies, run `COMPLETE_RLS_FIX.sql` again.

---

## Why This Happened

Multiple database migrations over time created duplicate policies. One policy referenced `collaborator_ids` which caused Postgres to query `collections` while evaluating a `collections` policy → infinite recursion.

---

**That's it!** Run the SQL → Restart app → Works! 🎉

