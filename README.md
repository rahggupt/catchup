# Mindmap Aggregator

A personalized and collaborative knowledge-building mobile app built with Flutter.

## Features

- 📰 Personalized content feed from trusted sources
- 📁 Collections system for organizing articles
- 🤖 AI-powered chat with RAG (Retrieval Augmented Generation)
- 👥 Social features and collaborative collections
- 🎨 Beautiful UI with swipe gestures

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Edge Functions, Storage)
- **AI Chat**: Google Gemini API
- **Embeddings**: Hugging Face Inference API
- **Vector DB**: Qdrant Cloud
- **State Management**: Riverpod

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Supabase account
- Google Gemini API key
- Qdrant Cloud instance

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure environment variables (see .env.example)
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── feed/
│   ├── collections/
│   ├── ai_chat/
│   └── profile/
└── shared/
    ├── models/
    ├── widgets/
    └── services/
```

## License

Private - All Rights Reserved

