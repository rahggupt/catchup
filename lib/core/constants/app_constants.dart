/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'CatchUp';
  static const String appVersion = '1.0.0';
  
  // API Endpoints (to be configured)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String qdrantUrl = String.fromEnvironment(
    'QDRANT_URL',
    defaultValue: '',
  );
  static const String qdrantApiKey = String.fromEnvironment(
    'QDRANT_API_KEY',
    defaultValue: '',
  );
  static const String huggingFaceApiKey = String.fromEnvironment(
    'HUGGINGFACE_API_KEY',
    defaultValue: '',
  );
  
  // Pagination
  static const int feedPageSize = 20;
  static const int collectionsPageSize = 10;
  static const int messagesPageSize = 50;
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedImages = 100;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // AI
  static const String defaultAiProvider = 'gemini';
  static const int maxTokens = 2000;
  static const double temperature = 0.7;
  
  // Embeddings
  static const String embeddingModel = 'sentence-transformers/all-MiniLM-L6-v2';
  static const int embeddingDimensions = 384;
  static const int maxContextArticles = 5;
}

