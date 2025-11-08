# 🔧 Stats Display Fix Guide

## Problem

You reported:
1. ✅ Created 1 collection in DB
2. ❌ UI shows "Collections: 0"
3. ❌ Added article to collection, count didn't increase

## Root Cause

The `stats` field in the `users` table isn't being updated automatically when you create collections or add articles.

---

## ✅ Solution: Run SQL Script

### Step 1: Run the Fix Script

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy contents of `fix_stats.sql`
3. Paste and click **Run**

This will:
- ✅ Calculate actual counts from database
- ✅ Update `stats` field with correct numbers
- ✅ Create triggers to auto-update stats in future
- ✅ Show verification results

### Step 2: Verify in App

1. **Close and reopen the app** (or hot reload)
2. Go to **Profile** tab
3. Check "My Stats" section
4. Should now show:
   - Collections: 1 (or your actual count)
   - Articles: X (based on how many you've added)

---

## 🎯 What the SQL Does

### Part 1: Immediate Fix
```sql
-- Updates your stats RIGHT NOW based on actual database counts
UPDATE users u
SET stats = jsonb_build_object(
    'articles', (actual count),
    'collections', (actual count),
    'chats', (actual count)
);
```

### Part 2: Auto-Update Triggers
Creates database triggers that automatically update stats when you:
- ✅ Create a collection → Stats update automatically
- ✅ Delete a collection → Stats update automatically  
- ✅ Add article to collection → Stats update automatically
- ✅ Remove article from collection → Stats update automatically

---

## 🧪 Test After Running SQL

### Test 1: Create Collection
```
1. Swipe right on article
2. Click "Create New Collection"
3. Name it "Test Stats"
4. Create & Add
5. Go to Profile → Should show Collections: 2
```

### Test 2: Add Article
```
1. Swipe right on another article
2. Select existing collection
3. Add to Collection
4. Go to Profile → Should show Articles: increased
```

### Test 3: Verify Counts Match
```sql
-- Run this to compare DB vs displayed stats
SELECT 
    u.email,
    u.stats->'collections' as stats_collections,
    (SELECT COUNT(*) FROM collections WHERE owner_id = u.uid) as actual_collections,
    u.stats->'articles' as stats_articles,
    (SELECT COUNT(DISTINCT ca.article_id) 
     FROM collections c 
     JOIN collection_articles ca ON c.id = ca.collection_id 
     WHERE c.owner_id = u.uid) as actual_articles
FROM users u;
```

---

## 📊 Before vs After

### Before (Broken):
```
Database:
✅ collections table: 1 row
❌ users.stats.collections: 0

App Display:
❌ Collections: 0 (wrong!)
```

### After (Fixed):
```
Database:
✅ collections table: 1 row
✅ users.stats.collections: 1

App Display:
✅ Collections: 1 (correct!)
```

---

## 🔍 Debugging

If stats still show 0 after running SQL:

### Check 1: Verify SQL Ran Successfully
```sql
-- Should show your actual counts
SELECT 
    email,
    stats->'collections' as collections,
    stats->'articles' as articles
FROM users;
```

### Check 2: Check Collections Ownership
```sql
-- Make sure collections have correct owner_id
SELECT 
    id,
    name,
    owner_id,
    privacy
FROM collections
WHERE owner_id = 'YOUR_USER_ID';
```

### Check 3: Force Refresh in App
```dart
// In Profile screen, pull down to refresh
// Or hot reload: Press 'r' in terminal
```

### Check 4: Clear App Cache
```bash
# Stop the app
# Delete browser cache/local storage
# Restart with: ./run_with_env.sh
```

---

## 🚀 Additional Features

The SQL script also adds:

### 1. **Real-time Stats Updates**
No need to manually refresh - stats update automatically when you:
- Create/delete collections
- Add/remove articles

### 2. **Accurate Counts**
- Articles count = **unique articles** across all your collections
- Collections count = total collections you own
- Chats count = AI chat sessions

### 3. **Trigger Functions**
Two PostgreSQL functions created:
- `update_user_stats()` - For collections
- `update_user_stats_on_article()` - For articles

---

## ❓ FAQ

**Q: Do I need to run this SQL every time?**  
A: No! Once you run it, triggers will auto-update stats forever.

**Q: Will this affect other users?**  
A: It updates stats for ALL users, but only based on their own data.

**Q: Can I customize what's counted?**  
A: Yes! Edit the SQL's `jsonb_build_object()` section.

**Q: What if I delete a collection?**  
A: Stats will automatically decrease (thanks to triggers).

---

## ✅ Expected Result

After running `fix_stats.sql`:

```
Profile Screen:
┌─────────────────────────┐
│      My Stats           │
├─────────────────────────┤
│  Articles    │    X     │  ← Correct count
│  Collections │    1+    │  ← Fixed! Shows 1
│  Chats       │    0     │  ← Works
└─────────────────────────┘
```

Run the script now and your stats will be fixed! 🎉

