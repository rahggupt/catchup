# Setup Guide

## Prerequisites

1. **Flutter SDK** (version 3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (comes with Flutter)

3. **IDE** (VS Code, Android Studio, or IntelliJ)

4. **Device/Emulator**
   - iOS: Xcode and iOS Simulator (macOS only)
   - Android: Android Studio and Android Emulator

## Backend Setup

### 1. Supabase Configuration

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from Project Settings > API
3. Create the following tables in Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE users (
  uid UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  avatar TEXT,
  bio TEXT,
  stats JSONB DEFAULT '{"articles": 0, "collections": 0, "chats": 0}'::jsonb,
  settings JSONB DEFAULT '{"anonymous_adds": false, "friend_updates": true}'::jsonb,
  ai_provider JSONB DEFAULT '{"provider": "gemini", "api_key": null}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sources table
CREATE TABLE sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  topics TEXT[] DEFAULT '{}',
  active BOOLEAN DEFAULT true,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Articles table
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  content TEXT,
  source TEXT NOT NULL,
  author TEXT,
  published_at TIMESTAMP WITH TIME ZONE,
  image_url TEXT,
  url TEXT NOT NULL,
  topic TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collections table
CREATE TABLE collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES users(uid) ON DELETE CASCADE,
  privacy TEXT CHECK (privacy IN ('private', 'invite', 'public')) DEFAULT 'private',
  collaborator_ids UUID[] DEFAULT '{}',
  stats JSONB DEFAULT '{"article_count": 0, "chat_count": 0, "contributor_count": 1}'::jsonb,
  shareable_link TEXT,
  cover_image TEXT,
  preview TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collection articles table
CREATE TABLE collection_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
  added_by UUID REFERENCES users(uid) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(collection_id, article_id)
);

-- Chats table
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  title TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user', 'ai')) NOT NULL,
  content TEXT NOT NULL,
  citations JSONB DEFAULT '[]'::jsonb,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies (basic - adjust as needed)
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = uid);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = uid);

CREATE POLICY "Users can view own sources" ON sources
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own and shared collections" ON collections
  FOR SELECT USING (
    auth.uid() = owner_id OR 
    auth.uid() = ANY(collaborator_ids)
  );
```

### 2. Google Gemini API

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key for Gemini
3. Save the API key

### 3. Qdrant Cloud

1. Create account at [cloud.qdrant.io](https://cloud.qdrant.io)
2. Create a free cluster (1GB)
3. Note your cluster URL and API key
4. Create a collection with 384 dimensions (for HuggingFace embeddings):
   ```python
   from qdrant_client import QdrantClient
   from qdrant_client.models import Distance, VectorParams
   
   client = QdrantClient(url="YOUR_URL", api_key="YOUR_KEY")
   
   client.create_collection(
       collection_name="articles",
       vectors_config=VectorParams(size=384, distance=Distance.COSINE)
   )
   ```

### 4. Hugging Face API (Optional for embeddings)

1. Sign up at [huggingface.co](https://huggingface.co)
2. Go to Settings > Access Tokens
3. Create a new token (read access is sufficient)

## Project Setup

1. **Clone the repository** (if from Git)
   ```bash
   cd "/Users/rahulg/Catch Up/mindmap_aggregator"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your API keys:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_anon_key
   GEMINI_API_KEY=your_gemini_key
   QDRANT_URL=https://your-cluster.qdrant.io
   QDRANT_API_KEY=your_qdrant_key
   HUGGINGFACE_API_KEY=your_hf_key
   ```

4. **Run code generation** (for Riverpod)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   # For iOS (macOS only)
   flutter run -d ios
   
   # For Android
   flutter run -d android
   
   # Or select device from VS Code/Android Studio
   ```

## Running with Environment Variables

Since Flutter doesn't support .env files natively, you need to pass environment variables at build/run time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=QDRANT_URL=your_url \
  --dart-define=QDRANT_API_KEY=your_key \
  --dart-define=HUGGINGFACE_API_KEY=your_key
```

**Tip**: Create a launch configuration in VS Code or Android Studio with these arguments.

## Development Mode

For development, you can temporarily hardcode the values in `lib/core/constants/app_constants.dart` (DO NOT commit these):

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your_anon_key';
// etc...
```

## Testing

Currently using mock data. The app will work without API configuration for testing UI/UX.

To test with real data:
1. Complete backend setup above
2. Configure environment variables
3. The app will automatically switch from mock to real data

## Troubleshooting

### Flutter not found
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### iOS build fails
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

### Android build fails
- Ensure Android SDK is installed
- Check `android/local.properties` has correct SDK path
- Run `flutter doctor` to check for issues

### Dependencies conflict
```bash
flutter clean
rm pubspec.lock
flutter pub get
```

## Next Steps

1. Configure all backend services
2. Test authentication flow
3. Add your news sources
4. Start curating articles into collections
5. Chat with your AI assistant

## Support

For issues:
1. Check `flutter doctor` output
2. Ensure all API keys are correct
3. Verify network connectivity
4. Check Supabase/Qdrant dashboards for errors

