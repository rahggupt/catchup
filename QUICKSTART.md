# Quick Start Guide

Get your Mindmap Aggregator app running in minutes!

## Prerequisites

- Flutter installed (`flutter --version`)
- Code editor (VS Code or Android Studio)
- Device/Emulator (iOS Simulator or Android Emulator)

## Option 1: Run with Mock Data (Fastest)

Perfect for testing UI/UX without setting up backend services.

```bash
# 1. Navigate to project
cd "/Users/rahulg/Catch Up/mindmap_aggregator"

# 2. Get dependencies
flutter pub get

# 3. Run the app
flutter run
```

That's it! The app will run with mock data and you can test all features.

## Option 2: Run with Real Backend

### Step 1: Set Up Supabase (5 minutes)

1. Go to [supabase.com](https://supabase.com) and create account
2. Create new project
3. Go to SQL Editor and run this:

```sql
-- Create users table
CREATE TABLE users (
  uid UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  stats JSONB DEFAULT '{"articles": 0, "collections": 0, "chats": 0}'::jsonb,
  settings JSONB DEFAULT '{"anonymous_adds": false, "friend_updates": true}'::jsonb,
  ai_provider JSONB DEFAULT '{"provider": "gemini"}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = uid);
```

4. Get your credentials from Project Settings > API:
   - Project URL
   - Anon/Public key

### Step 2: Get Gemini API Key (2 minutes)

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Copy the key

### Step 3: Set Up Qdrant (3 minutes)

1. Go to [cloud.qdrant.io](https://cloud.qdrant.io)
2. Create free account
3. Create cluster (1GB free)
4. Note URL and API key

### Step 4: Run with Your Keys

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --dart-define=QDRANT_URL=https://your-cluster.qdrant.io \
  --dart-define=QDRANT_API_KEY=your_qdrant_key
```

## What You'll See

### 1. Splash Screen
The app checks authentication status.

### 2. Login/Signup
Create an account or sign in with Google.

### 3. Feed Tab (Home)
- Swipe left to dismiss articles
- Swipe right to save to collection
- Tap to expand article details
- Use filter chips to narrow content

### 4. Collections Tab
- View your saved collections
- Tap to see collection details
- FAB (+) to create new collection

### 5. Ask AI Tab
- Chat with AI about your articles
- AI uses RAG (Retrieval-Augmented Generation)
- See citations from your saved articles
- Filter by specific collection

### 6. Profile Tab
- View your stats
- Manage news sources
- Configure AI provider
- Adjust privacy settings

## Testing the App

### Test Authentication
1. Sign up with email
2. Logout
3. Try Google Sign-In
4. Verify navigation works

### Test Feed
1. Swipe through articles
2. Try left/right swipes
3. Test filter chips
4. Like an article
5. Expand article details

### Test AI Chat
1. Ask: "Summarize AI articles"
2. Try suggested queries
3. Check citations appear
4. Filter by collection

## Troubleshooting

### "Flutter not found"
```bash
# Add to PATH (macOS/Linux)
export PATH="$PATH:/path/to/flutter/bin"
```

### "No devices found"
```bash
# iOS
open -a Simulator

# Android
# Open Android Studio > AVD Manager > Start emulator
```

### App won't build
```bash
flutter clean
rm pubspec.lock
flutter pub get
flutter run
```

### API not working
- Check internet connection
- Verify API keys are correct
- Check Supabase dashboard for errors
- Ensure Qdrant cluster is running

## Next Steps

1. **Customize**
   - Add your favorite news sources
   - Create collections for topics you care about
   - Configure AI provider (default is Gemini)

2. **Test Features**
   - Save articles to collections
   - Ask AI questions about your content
   - Invite friends (when implemented)

3. **Deploy**
   - See `DEPLOYMENT.md` for app store submission
   - Add app icons and splash screens
   - Configure production environment

## Project Files

- `README.md` - Project overview
- `SETUP.md` - Detailed setup with database schema
- `DEPLOYMENT.md` - App Store & Play Store guide
- `PROJECT_SUMMARY.md` - Complete technical overview
- `QUICKSTART.md` - This file

## Support

- Check `PROJECT_SUMMARY.md` for architecture details
- See `SETUP.md` for troubleshooting
- Read `DEPLOYMENT.md` when ready to publish

## Cost Overview

With free tiers:
- ✅ Development: $0
- ✅ Up to 50 users: $0
- ✅ 1,000 AI queries/month: $0
- ⚠️ 100-500 users: ~$25-50/month
- 📈 1,000+ users: ~$100-200/month

## Key Features

✅ Authentication (Email, Google OAuth)  
✅ Swipeable article feed (Tinder-style)  
✅ Collections with privacy tiers  
✅ AI chat with RAG (Retrieval-Augmented Generation)  
✅ Source management  
✅ Profile & settings  
✅ Loading states & error handling  

## Tech Stack Summary

- Frontend: Flutter
- Backend: Supabase (PostgreSQL)
- AI: Google Gemini API
- Vector DB: Qdrant
- Embeddings: Hugging Face
- State: Riverpod

---

**Ready to build your personal knowledge hub? Start with Option 1 and explore! 🚀**

