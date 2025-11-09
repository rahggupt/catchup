# 🔧 Critical Fixes In Progress

## Issues Identified

1. ❌ **Source toggle not persisting** - Disabled source still shows articles
2. ❌ **Article count not configurable** - Need default 5, user adjustable  
3. ❌ **Images not loading** - RSS images not being extracted properly
4. ❌ **No delete functionality** - Can't delete collections or sources
5. ❌ **Stats showing wrong numbers** - Shows 45 articles but 0 in DB
6. ❌ **Wrong UI** - Should be single article view with swipe, not scrollable list

---

## Fixes Applied So Far

### ✅ 1. Source Toggle Persistence
**Changes**:
- Made `feedArticlesProvider` `autoDispose` to rebuild when sources change
- Added source listener that triggers `forceRefresh()` when sources change
- Provider now watches `userSourcesProvider` reactively

**Files Modified**:
- `lib/features/feed/presentation/providers/rss_feed_provider.dart`

**Testing**: Disable source → Go to feed → Tap refresh → Should not see articles from that source

---

### ✅ 2. Article Count Configuration
**Changes**:
- Added `articleCount` field to `SourceModel` (default: 5)
- RSS service now accepts `limit` parameter
- Provider reads `articleCount` from each source
- RSS fetches only specified number of articles per source

**Files Modified**:
- `lib/shared/models/source_model.dart` 
- `lib/shared/services/rss_feed_service.dart`
- `lib/features/feed/presentation/providers/rss_feed_provider.dart`

**Database Update Needed**:
```sql
-- Add article_count column to sources table
ALTER TABLE sources 
ADD COLUMN article_count INTEGER DEFAULT 5;
```

**Testing**: Check console logs for "limit: 5" when fetching

---

### ✅ 3. Image Loading Fix
**Changes**:
- Added better Accept headers for RSS feeds
- Added HTML image extraction from description
- Added logging to debug image URLs
- Tries multiple sources: media:content → enclosure → thumbnail → HTML img tag → placeholder

**Files Modified**:
- `lib/shared/services/rss_feed_service.dart`

**Testing**: Check console for "Found media content URL" or "Found image in description"

---

## Fixes Still Needed

### ⏳ 4. Delete Functionality
**What**: Add delete buttons for collections and sources

**Plan**:
- Add delete icon to collection cards
- Add delete icon to source cards  
- Show confirmation dialog
- Call Supabase service delete methods
- Refresh UI

### ⏳ 5. Fix Stats from DB
**Problem**: Stats show wrong numbers (e.g., 45 articles when 0 in DB)

**Root Cause**: Stats likely read from cached/hardcoded values instead of real DB counts

**Plan**:
- Profile provider should query actual DB counts
- Count articles: `SELECT COUNT(*) FROM collection_articles WHERE collection_id IN (user collections)`
- Count collections: `SELECT COUNT(*) FROM collections WHERE owner_id = user_id`

### ⏳ 6. Revert to Single Article View
**Critical**: User wants original swipe interface back

**Requirements**:
- Show ONE article at a time (full screen)
- Swipe right → Save to collection
- Swipe left → Dismiss
- Swipe up → Load next article
- Progress indicator showing X/total articles

**Plan**:
- Use original `feed_screen.dart` with `SwipeableArticleCard`
- Keep RSS feed data (don't go back to mock data)
- Use `flutter_card_swiper` package
- Update navigation to use original feed screen

---

## Testing Checklist

Once all fixes are complete:

- [ ] Disable source in profile → Refresh feed → Articles from that source should NOT appear
- [ ] Check console: Should fetch only 5 articles per source
- [ ] Images should load for most articles
- [ ] Can delete a collection → Collection disappears
- [ ] Can delete a source → Source disappears
- [ ] Profile stats match actual DB counts (collections and articles)
- [ ] Feed shows ONE article at a time
- [ ] Swipe right on article → Saves to collection
- [ ] Swipe left on article → Dismisses
- [ ] Swipe up → Shows next article
- [ ] Progress indicator shows current position (e.g., "3/25")

---

## Commands to Run

```bash
# After database schema changes
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# Apply SQL migration (add article_count column)
# Run in Supabase SQL Editor:
ALTER TABLE sources ADD COLUMN IF NOT EXISTS article_count INTEGER DEFAULT 5;

# Restart app
flutter run -d chrome
```

---

## Next Steps

1. ✅ Revert feed to single article view with swipe
2. Add delete collection functionality
3. Add delete source functionality
4. Fix stats to read from DB
5. Test all fixes

---

**Status**: Fixes 1-3 complete. Working on fix #6 (single article view) next.

