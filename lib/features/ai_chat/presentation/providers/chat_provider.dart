import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../../shared/providers/ai_service_provider.dart';

// Selected collection for AI chat
final selectedChatCollectionProvider = StateProvider<String?>((ref) => null);

// AI thinking state (locks input while processing)
final isAiThinkingProvider = StateProvider<bool>((ref) => false);

// Current chat session ID
final currentChatSessionProvider = StateProvider<String?>((ref) => null);

// Chat messages for current session
final chatMessagesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final logger = LoggerService();
  final sessionId = ref.watch(currentChatSessionProvider);
  
  if (sessionId == null) {
    return Stream.value([]);
  }
  
  logger.info('Fetching messages for chat session: $sessionId', category: 'Chat');
  
  return SupabaseConfig.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', sessionId)
      .order('created_at', ascending: true) // Explicitly set ascending for chronological order
      .map((data) {
        final messages = List<Map<String, dynamic>>.from(data);
        logger.info('Received ${messages.length} messages in chronological order', category: 'Chat');
        return messages;
      });
});

// Provider to create a new chat session
final createChatSessionProvider = Provider<Future<String> Function(String?)>((ref) {
  final logger = LoggerService();
  return (String? collectionId) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Don't include collection_id if it's an article-specific chat (not a valid UUID)
      final isValidCollectionId = collectionId != null && 
                                    !collectionId.startsWith('article_') &&
                                    collectionId.isNotEmpty;
      
      final insertData = <String, dynamic>{
        'user_id': user.id,
        'title': isValidCollectionId ? 'New Chat' : 'Article Chat',
      };
      
      // Only add collection_id if it's a valid UUID
      if (isValidCollectionId) {
        insertData['collection_id'] = collectionId;
      }
      
      logger.info('Creating chat session: ${isValidCollectionId ? "with collection $collectionId" : "for article"}', category: 'Chat');
      
      // Create chat in database
      final chatData = await SupabaseConfig.client
          .from('chats')
          .insert(insertData)
          .select()
          .single();
      
      final chatId = chatData['id'] as String;
      logger.success('Chat session created: $chatId', category: 'Chat');
      
      // Set as current session
      ref.read(currentChatSessionProvider.notifier).state = chatId;
      
      return chatId;
    } catch (e, stackTrace) {
      logger.error('Failed to create chat session', category: 'Chat', error: e, stackTrace: stackTrace);
      rethrow;
    }
  };
});

// Provider to send a message
final sendMessageProvider = Provider<Future<void> Function(String)>((ref) {
  final logger = LoggerService();
  return (String message) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Check if AI is already thinking
      if (ref.read(isAiThinkingProvider)) {
        logger.warning('AI is already processing a message', category: 'Chat');
        throw Exception('Please wait for AI to respond');
      }
      
      // Get or create chat session
      var sessionId = ref.read(currentChatSessionProvider);
      if (sessionId == null) {
        final collectionId = ref.read(selectedChatCollectionProvider);
        sessionId = await ref.read(createChatSessionProvider)(collectionId);
      }
      
      logger.info('Sending message to chat session: $sessionId', category: 'Chat');
      
      // Set AI thinking state
      ref.read(isAiThinkingProvider.notifier).state = true;
      
      // Save user message
      await SupabaseConfig.client.from('messages').insert({
        'chat_id': sessionId,
        'role': 'user',
        'content': message,
      });
      
      // Get AI response with RAG
      logger.info('Requesting AI response', category: 'Chat');
      final aiService = await ref.read(aiServiceProvider.future);
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
      
      logger.success('Message and AI response saved successfully', category: 'Chat');
    } catch (e, stackTrace) {
      logger.error('Failed to send message', category: 'Chat', error: e, stackTrace: stackTrace);
      rethrow;
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
  final aiService = await ref.watch(aiServiceProvider.future);
  return await aiService.isCollectionIndexed(collectionId);
});

// Provider to index a collection
final indexCollectionProvider = Provider<Future<void> Function(String)>((ref) {
  return (String collectionId) async {
    final aiService = await ref.read(aiServiceProvider.future);
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

// Provider to send article for summary (auto-generates summary on chat open)
final sendArticleSummaryProvider = Provider<Future<void> Function(ArticleModel)>((ref) {
  final logger = LoggerService();
  return (ArticleModel article) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Check if AI is already thinking
      if (ref.read(isAiThinkingProvider)) {
        logger.warning('AI is already processing, cannot generate summary now', category: 'Chat');
        throw Exception('Please wait for AI to respond');
      }
      
      logger.info('Generating article summary for: ${article.title}', category: 'Chat');
      
      // Get or create chat session with article-specific collection ID for RAG
      var sessionId = ref.read(currentChatSessionProvider);
      if (sessionId == null) {
        // Use article-specific collection ID for RAG context
        final tempCollectionId = 'article_${article.id}';
        ref.read(selectedChatCollectionProvider.notifier).state = tempCollectionId;
        sessionId = await ref.read(createChatSessionProvider)(tempCollectionId);
      }
      
      // Set AI thinking state
      ref.read(isAiThinkingProvider.notifier).state = true;
      
      // Save system message with article context
      await SupabaseConfig.client.from('messages').insert({
        'chat_id': sessionId,
        'role': 'system',
        'content': 'Summarizing article: "${article.title}" from ${article.source}',
      });
      
      // Get AI summary (this will also index the article for RAG)
      logger.info('Requesting AI to generate article summary', category: 'Chat');
      final aiService = await ref.read(aiServiceProvider.future);
      final summary = await aiService.getArticleSummary(article);
      
      // Save AI summary response
      await SupabaseConfig.client.from('messages').insert({
        'chat_id': sessionId,
        'role': 'assistant',
        'content': summary,
      });
      
      logger.success('Article summary generated and indexed for RAG', category: 'Chat');
    } catch (e, stackTrace) {
      logger.error('Failed to generate article summary: ${article.title}', category: 'Chat', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      // Clear AI thinking state
      ref.read(isAiThinkingProvider.notifier).state = false;
    }
  };
});

