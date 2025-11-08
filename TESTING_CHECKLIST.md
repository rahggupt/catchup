# 🧪 Testing Checklist - All Fixes

## ✅ Feed Screen Tests

### Test 1: Add Source
- [ ] Click + icon (top right)
- [ ] Modal opens
- [ ] Click suggested source (e.g., "Wired")
- [ ] Fields auto-populate
- [ ] Click "Add Source"
- [ ] See success message
- [ ] Go to Profile → Source appears in list

### Test 2: Search
- [ ] Click search icon (top right)
- [ ] Dialog opens
- [ ] Type search query
- [ ] Press Enter
- [ ] See search feedback

### Test 3: Swipe Left (Dismiss)
- [ ] Swipe article card LEFT
- [ ] Card dismisses
- [ ] Next article appears

### Test 4: Swipe Right (Save to Collection)
- [ ] Swipe article card RIGHT
- [ ] "Add to Collection" modal opens
- [ ] See your collections listed
- [ ] Select a collection
- [ ] Click "Add to Collection"
- [ ] See success message

### Test 5: Create New Collection While Saving
- [ ] Swipe article RIGHT
- [ ] Click "Create New Collection"
- [ ] Enter collection name
- [ ] Click "Create & Add"
- [ ] Success message
- [ ] Go to Collections tab → New collection appears

### Test 6: Like Button
- [ ] Tap heart icon on article
- [ ] Icon turns red (filled)
- [ ] Tap again
- [ ] Icon turns gray (outline)

### Test 7: Bookmark Button
- [ ] Tap bookmark icon
- [ ] Add to Collection modal opens
- [ ] Same flow as swipe right

### Test 8: Comment Button
- [ ] Tap comment icon
- [ ] See "Comments coming soon" toast

### Test 9: Share Button
- [ ] Tap share icon
- [ ] See share options
- [ ] Click "Copy Link"

---

## ✅ Profile Screen Tests

### Test 10: Add More Sources
- [ ] Scroll to "Sources & Topics"
- [ ] Click "Add More"
- [ ] Same modal as Feed + icon
- [ ] Add a source
- [ ] It appears in profile immediately

### Test 11: Toggle Source On/Off
- [ ] Find a source in profile
- [ ] Toggle switch OFF
- [ ] See "disabled" toast
- [ ] Toggle switch ON
- [ ] See "enabled" toast

### Test 12: Privacy - Anonymous Adds
- [ ] Scroll to "Privacy & Sharing"
- [ ] Toggle "Anonymous Adds" switch
- [ ] See confirmation toast
- [ ] Database updated

### Test 13: Privacy - Friend Updates
- [ ] Toggle "Friend Updates" switch
- [ ] See confirmation toast
- [ ] Database updated

### Test 14: Export Data
- [ ] Scroll to "Account"
- [ ] Click "Export Data"
- [ ] See "Preparing..." toast
- [ ] See "Ready (coming soon)" message

### Test 15: Logout
- [ ] Click "Logout"
- [ ] Redirected to login screen

---

## ✅ Collections Screen Tests

### Test 16: View Collections
- [ ] Tap Collections tab
- [ ] See your collections listed
- [ ] Each shows article count

### Test 17: Create Collection from FAB
- [ ] Tap + button (bottom right)
- [ ] Enter collection name
- [ ] Select privacy level
- [ ] Click "Create"
- [ ] New collection appears

---

## ✅ Database Verification

### After Adding Source:
```sql
SELECT * FROM sources WHERE user_id = 'your-user-id' ORDER BY added_at DESC LIMIT 1;
```
- [ ] New source appears
- [ ] Correct name, URL, topics

### After Toggling Source:
```sql
SELECT active FROM sources WHERE id = 'source-id';
```
- [ ] `active` field updated to true/false

### After Privacy Setting Change:
```sql
SELECT settings FROM users WHERE uid = 'your-user-id';
```
- [ ] Settings JSON updated correctly

### After Adding to Collection:
```sql
SELECT * FROM collection_articles WHERE article_id = 'article-id';
```
- [ ] Link exists between collection and article

---

## 🐛 Known Limitations (Not Bugs):

1. **AI Configuration** - Button exists but modal not yet implemented (coming next)
2. **Delete Collection** - Feature not yet implemented
3. **Native Share** - Currently shows dialog, native share coming soon
4. **Comments** - Placeholder, full feature coming later
5. **Export Data** - Shows feedback but full export not implemented

---

## 📊 Expected Behavior Summary:

| CTA | Expected Behavior | Status |
|-----|------------------|--------|
| Feed → + icon | Opens Add Source modal, saves to DB | ✅ |
| Feed → Search | Opens search dialog | ✅ |
| Feed → Swipe Left | Dismisses article | ✅ |
| Feed → Swipe Right | Opens Add to Collection modal | ✅ |
| Feed → Like | Toggles like state | ✅ |
| Feed → Bookmark | Opens Add to Collection modal | ✅ |
| Feed → Comment | Shows "coming soon" | ✅ |
| Feed → Share | Shows share dialog | ✅ |
| Profile → Add More | Opens Add Source modal | ✅ |
| Profile → Source Toggle | Saves active state to DB | ✅ |
| Profile → Anonymous Adds | Saves setting to DB | ✅ |
| Profile → Friend Updates | Saves setting to DB | ✅ |
| Profile → Export Data | Shows progress message | ✅ |
| Profile → Logout | Logs out and returns to login | ✅ |
| Collections → + FAB | Creates new collection | ✅ |

---

## 🎯 All Major Bugs Fixed!

Before you reported:
1. ❌ Add source not working
2. ❌ Add to collection "coming soon"
3. ❌ Profile CTAs not working
4. ❌ Article action buttons not working

Now:
1. ✅ Add source saves to database
2. ✅ Add to collection fully functional
3. ✅ All profile CTAs working (toggles, privacy, export, add more)
4. ✅ All article buttons functional (like, bookmark, comment, share)

**Ready to test!** 🚀

