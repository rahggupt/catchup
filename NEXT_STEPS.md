# Next Steps - User Action Required

## 🎉 Implementation Complete!

All feature development is complete. The following manual steps are required to fully activate the new features:

---

## 1. ⚠️ Database Migrations (REQUIRED)

### Step 1: Apply Collection Sharing Schema
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `database/collection_sharing_schema.sql`
3. Click "Run" to execute
4. Verify success message

**What this does:**
- Creates `collection_members` table
- Creates `collection_invites` table
- Adds `shareable_token` and `share_enabled` columns to `collections`
- Sets up RLS policies for secure sharing
- Creates `generate_shareable_token()` and `accept_collection_invite()` functions

### Step 2: Apply Collection Stats Triggers
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `database/collection_stats_triggers.sql`
3. Click "Run" to execute
4. Verify success message

**What this does:**
- Creates `recalculate_collection_stats()` function
- Sets up automatic triggers on article/member/chat changes
- Recalculates stats for all existing collections

### Step 3: (Optional) Fix RLS Issues
If you experience any RLS recursion errors:
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `database/NUCLEAR_RLS_FIX.sql`
3. Click "Run" to execute

---

## 2. 🔑 Perplexity API Configuration (OPTIONAL)

To enable Perplexity AI integration:

1. Get an API key from [Perplexity](https://www.perplexity.ai/)
2. Add to your `.env` file:
   ```
   PERPLEXITY_API_KEY=your_key_here
   ```
3. Rebuild the app
4. Go to Profile → AI Settings
5. Select "Perplexity AI"
6. Save configuration

**Note:** If no API key is provided, the app will continue using Gemini by default.

---

## 3. 🔨 Build & Test

### Build Debug Version (with logging):
```bash
cd mindmap_aggregator
./build_apk_java21.sh debug
```

### Build Release Version:
```bash
cd mindmap_aggregator
./build_apk_java21.sh
```

### Install on Device:
The script automatically installs the APK. Or manually:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. ✅ Testing Checklist

### Test Collection Sharing:
1. **Create a shared collection:**
   - [ ] Create a new collection
   - [ ] Set privacy to "Invite-Only" or "Public"
   - [ ] Click the menu (⋮) → "Share"
   - [ ] Generate a shareable link

2. **Accept an invite:**
   - [ ] Open the link on another device/account
   - [ ] Accept the invite
   - [ ] Verify the collection appears in both accounts

3. **Collaborate:**
   - [ ] Add an article from Account A
   - [ ] Verify it appears in Account B (realtime sync)
   - [ ] Remove an article from Account B
   - [ ] Verify it disappears in Account A

4. **Manage members:**
   - [ ] Click "Manage Members" from collection menu
   - [ ] Change a member's role (Viewer → Editor)
   - [ ] Remove a member
   - [ ] Verify permissions are enforced

### Test Perplexity AI:
1. **Configure Perplexity:**
   - [ ] Go to Profile → AI Settings
   - [ ] Select "Perplexity AI"
   - [ ] Add API key (if you have one)
   - [ ] Save

2. **Test AI responses:**
   - [ ] Open an article
   - [ ] Click "Ask AI"
   - [ ] Ask a question about the article
   - [ ] Verify response includes article context + web knowledge
   - [ ] Compare response quality with Gemini

### Test UI Improvements:
1. **Privacy badges:**
   - [ ] Go to Collections tab
   - [ ] Verify each collection shows a colored privacy badge
     - Blue 🔒 = Private
     - Orange 👥 = Invite-Only
     - Green 🌐 = Public

2. **Collection details:**
   - [ ] Tap on a collection card
   - [ ] Verify it opens the collection details screen
   - [ ] Tap an article to view it
   - [ ] Remove an article (if you have permission)

3. **Edit collection:**
   - [ ] Open collection menu → "Edit"
   - [ ] Change the name, description, cover image
   - [ ] Change privacy setting
   - [ ] Save and verify changes

### Test Debug Logs:
1. **View logs:**
   - [ ] In debug build, go to Profile
   - [ ] Scroll to "Debug Settings"
   - [ ] Tap "View Debug Logs"
   - [ ] Perform various actions (login, save article, etc.)
   - [ ] Refresh logs and verify they're captured

2. **Download logs:**
   - [ ] In Debug Logs screen, tap download button
   - [ ] Check Downloads folder for `catchup_logs_[timestamp].txt`
   - [ ] Open file and verify contents

---

## 5. 📊 Monitoring & Verification

### Check Stats Accuracy:
1. **Profile stats:**
   - Count your collections manually
   - Compare with "Collections" count in Profile
   - Create/delete a collection and verify count updates

2. **Collection stats:**
   - Open a collection
   - Count articles manually
   - Verify "Articles" count matches
   - Add/remove an article and verify count updates immediately

3. **Debug logs:**
   - In debug mode, check logs for any stat mismatches
   - Look for `category: 'Collections'` or `category: 'Database'`
   - Investigate any errors or warnings

### Check Message Ordering:
1. Open "Ask AI" on an article
2. Send 3-4 questions in sequence
3. Verify responses appear in correct order (chronological)
4. Check debug logs for message ordering confirmations

---

## 6. 🐛 Known Issues & Workarounds

### Issue: Stats Not Updating
**Solution:** Run the stats triggers SQL script again to recalculate all stats.

### Issue: RLS Recursion Error
**Solution:** Run `database/NUCLEAR_RLS_FIX.sql` to clean up duplicate policies.

### Issue: Perplexity Not Working
**Solution:** Verify API key is correct and has sufficient credits. The app will fall back to Gemini if Perplexity fails.

### Issue: Articles Not Syncing in Realtime
**Solution:** Check that Supabase Realtime is enabled for your project. Go to Supabase → Project Settings → API → Realtime.

---

## 7. 📝 Support

### View Logs:
1. Build with debug mode: `./build_apk_java21.sh debug`
2. Profile → Debug Logs
3. Download and review log file

### Database Issues:
1. Check Supabase Dashboard → Database → Tables
2. Verify all tables exist: `collections`, `collection_members`, `collection_articles`, `collection_invites`
3. Check RLS policies: Database → Policies

### API Issues:
1. Verify all API keys in `.env` are correct
2. Check API quotas (Gemini, Perplexity, Qdrant, Hugging Face)
3. Review logs for API error messages

---

## 8. 🚀 Future Enhancements (Phase 5+)

See `IMPLEMENTATION_SUMMARY.md` for detailed roadmap of:
- In-collection chat
- Activity feeds
- Advanced search
- Collection templates
- Push notifications
- Analytics dashboard
- Offline mode
- Share extensions

---

**Ready to go!** 🎊

Once you've completed the database migrations, all features will be fully functional. Happy testing!

