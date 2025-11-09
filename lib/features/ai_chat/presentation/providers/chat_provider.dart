import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../shared/services/supabase_service.dart';

// AI Service provider
final aiServiceProvider = Provider<AIService>((ref) {
  // These should match your .env file keys
  // For now using placeholder values - will be replaced with actual env vars
  return AIService(
    geminiApiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    qdrantUrl: const String.fromEnvironment('QDRANT_API_URL', defaultValue: ''),
    qdrantKey: const String.fromEnvironment('QDRANT_API_KEY', defaultValue: ''),
    huggingFaceKey: const String.fromEnvironment('HUGGING_FACE_API_KEY', defaultValue: ''),
  );
});

// Selected collection for AI chat
final selectedChatCollectionProvider = StateProvider<String?>((ref) => null);

// AI thinking state (locks input while processing)
final isAiThinkingProvider = StateProvider<bool>((ref) => false);

// Current chat session ID
final currentChatSessionProvider = StateProvider<String?>((ref) => null);

// Chat messages for current session
final chatMessagesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final sessionId = ref.watch(currentChatSessionProvider);
  
  if (sessionId == null) {
    return Stream.value([]);
  }
  
  return SupabaseConfig.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', sessionId)
      .order('created_at')
      .map((data) => List<Map<String, dynamic>>.from(data));
});

// Provider to create a new chat session
final createChatSessionProvider = Provider<Future<String> Function(String?)>((ref) {
  return (String? collectionId) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final supabaseService = SupabaseService();
    
    // Create chat in database
    final chatData = await SupabaseConfig.client
        .from('chats')
        .insert({
          'user_id': user.id,
          'collection_id': collectionId,
          'title': 'New Chat',
        })
        .select()
        .single();
    
    final chatId = chatData['id'] as String;
    
    // Set as current session
    ref.read(currentChatSessionProvider.notifier).state = chatId;
    
    return chatId;
  };
});

// Provider to send a message
final sendMessageProvider = Provider<Future<void> Function(String)>((ref) {
  return (String message) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    // Check if AI is already thinking
    if (ref.read(isAiThinkingProvider)) {
      throw Exception('Please wait for AI to respond');
    }
    
    // Get or create chat session
    var sessionId = ref.read(currentChatSessionProvider);
    if (sessionId == null) {
      final collectionId = ref.read(selectedChatCollectionProvider);
      sessionId = await ref.read(createChatSessionProvider)(collectionId);
    }
    
    try {
      // Set AI thinking state
      ref.read(isAiThinkingProvider.notifier).state = true;
      
      // Save user message
      await SupabaseConfig.client.from('messages').insert({
        'chat_id': sessionId,
        'role': 'user',
        'content': message,
      });
      
      // Get AI response with RAG
      final aiService = ref.read(aiServiceProvider);
      final collectionId = ref.read(selectedChatCollectionProvider);
      
      final response = await aiService.getChatResponseWithRAG(
        query: message,
        collectionId: collectionId,
      );
      
      // Save AI response
      await SupabaseConfig.client.from('messages').insert({
        'chat_id': sessionId,
        'role': 'assistant',
        'content': response,
      });
      
    } finally {
      // Clear AI thinking state
      ref.read(isAiThinkingProvider.notifier).state = false;
    }
  };
});

// Provider to get user's chat history
final chatHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return [];
  
  final response = await SupabaseConfig.client
      .from('chats')
      .select('*, messages(*)')
      .eq('user_id', user.id)
      .order('updated_at', ascending: false)
      .limit(20);
  
  return List<Map<String, dynamic>>.from(response as List);
});

// Provider to check if collection is indexed
final collectionIndexStatusProvider = FutureProvider.family<bool, String>((ref, collectionId) async {
  final aiService = ref.read(aiServiceProvider);
  return await aiService.isCollectionIndexed(collectionId);
});

// Provider to index a collection
final indexCollectionProvider = Provider<Future<void> Function(String)>((ref) {
  return (String collectionId) async {
    final aiService = ref.read(aiServiceProvider);
    final supabaseService = SupabaseService();
    
    // Get collection articles
    final articles = await supabaseService.getCollectionArticles(collectionId);
    
    // Index them
    await aiService.indexCollectionForRAG(
      collectionId: collectionId,
      articles: articles,
    );
  };
});

