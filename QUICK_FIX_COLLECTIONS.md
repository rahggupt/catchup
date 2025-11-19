# ⚡ Quick Fix - Collections Not Showing

## 🚨 The Problem
Your collections exist in the database but don't show in the app.

## ✅ The Solution (2 Steps)

### Step 1: Run This SQL in Supabase
```sql
-- Drop old policies
DROP POLICY IF EXISTS "collections_select_policy" ON collections;
DROP POLICY IF EXISTS "collections_insert_policy" ON collections;
DROP POLICY IF EXISTS "collections_update_policy" ON collections;
DROP POLICY IF EXISTS "collections_delete_policy" ON collections;

-- Create new policies
CREATE POLICY "collections_select_policy" ON collections
FOR SELECT USING (auth.uid() = owner_id OR privacy = 'public');

CREATE POLICY "collections_insert_policy" ON collections
FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "collections_update_policy" ON collections
FOR UPDATE USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "collections_delete_policy" ON collections
FOR DELETE USING (auth.uid() = owner_id);

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
```

### Step 2: Rebuild App
```bash
cd "/Users/rahulg/Catch Up/mindmap_aggregator"
flutter clean
./build_apk_java21.sh
```

## ✅ Done!
Your 3 collections (MyCollection, research, check) should now appear in both:
- Collections tab
- Add to Collection modal

---

For detailed explanation, see `FIX_COLLECTIONS_NOT_SHOWING.md`

