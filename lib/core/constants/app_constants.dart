import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'CatchUp';
  static const String appVersion = '1.0.0';
  
  // Debug Mode (set via --dart-define=DEBUG_MODE=true when building APK)
  static const bool debugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);
  
  // API Endpoints (loaded from .env or compile-time environment)
  static String get supabaseUrl => 
    dotenv.env['SUPABASE_URL'] ?? 
    const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    
  static String get supabaseAnonKey => 
    dotenv.env['SUPABASE_ANON_KEY'] ?? 
    const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
  static String get geminiApiKey => 
    dotenv.env['GEMINI_API_KEY'] ?? 
    const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    
  static String get qdrantUrl => 
    dotenv.env['QDRANT_API_URL'] ?? 
    const String.fromEnvironment('QDRANT_URL', defaultValue: '');
    
  static String get qdrantApiKey => 
    dotenv.env['QDRANT_API_KEY'] ?? 
    const String.fromEnvironment('QDRANT_API_KEY', defaultValue: '');
    
  static String get huggingFaceApiKey => 
    dotenv.env['HUGGING_FACE_API_KEY'] ?? 
    const String.fromEnvironment('HUGGINGFACE_API_KEY', defaultValue: '');
    
  static String get perplexityApiKey => 
    dotenv.env['PERPLEXITY_API_KEY'] ?? 
    const String.fromEnvironment('PERPLEXITY_API_KEY', defaultValue: '');
  
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
  static const String defaultAiProvider = 'gemini'; // 'gemini' or 'perplexity'
  static const int maxTokens = 2000;
  static const double temperature = 0.7;
  static const String perplexityModel = 'llama-3.1-sonar-small-128k-online';
  
  // Embeddings
  static const String embeddingModel = 'sentence-transformers/all-MiniLM-L6-v2';
  static const int embeddingDimensions = 384;
  static const int maxContextArticles = 5;
}

