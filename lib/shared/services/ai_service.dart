import 'dart:convert';
import 'package:http/http.dart' as http;
import 'qdrant_service.dart';
import 'hugging_face_service.dart';
import '../models/article_model.dart';
import '../../core/config/ai_prompts_config.dart';

/// Service for AI chat with RAG (Retrieval Augmented Generation)
class AIService {
  final String geminiApiKey;
  final QdrantService _qdrantService;
  final HuggingFaceService _hfService;
  
  AIService({
    required this.geminiApiKey,
    required String qdrantUrl,
    required String qdrantKey,
    required String huggingFaceKey,
  }) : _qdrantService = QdrantService(apiUrl: qdrantUrl, apiKey: qdrantKey),
       _hfService = HuggingFaceService(apiKey: huggingFaceKey);

  /// Generate AI response with RAG context from collection
  Future<String> getChatResponseWithRAG({
    required String query,
    required String? collectionId,
  }) async {
    try {
      print('🤖 Processing query with RAG: $query');
      
      String contextText = '';
      
      // If collection is specified, get RAG context
      if (collectionId != null && collectionId != 'all_sources') {
        print('📚 Fetching context from collection: $collectionId');
        
        // Check if collection exists in Qdrant
        final collectionName = 'collection_$collectionId';
        final exists = await _qdrantService.collectionExists(collectionName);
        
        if (!exists) {
          print('⚠️ Collection not indexed yet in Qdrant');
          contextText = 'Note: This collection has not been indexed yet for AI search. Responding based on general knowledge.';
        } else {
          // Get relevant articles from Qdrant
          final context = await _qdrantService.queryKnowledgeBase(
            collectionId: collectionId,
            query: query,
            getEmbeddings: _hfService.getEmbeddings,
            limit: 5,
          );
          
          if (context.isNotEmpty) {
            contextText = AIPromptsConfig.buildRagContext(context);
          }
        }
      }
      
      // Build prompt with context using centralized config
      final prompt = contextText.isNotEmpty
          ? AIPromptsConfig.getRagChatPrompt(
              contextText: contextText,
              userQuery: query,
            )
          : AIPromptsConfig.getGeneralChatPrompt(
              userQuery: query,
            );
      
      // Call Gemini API
      print('🔮 Calling Gemini API...');
      final response = await _generateGeminiResponse(prompt);
      
      print('✅ AI response generated successfully');
      return response;
    } catch (e) {
      print('❌ Error generating AI response: $e');
      return 'Sorry, I encountered an error processing your request. Please try again.';
    }
  }

  /// Generate response using Gemini API
  Future<String> _generateGeminiResponse(String prompt) async {
    try {
      // Using Gemini 2.0 Flash (Gemini 2.5 family) for better performance
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      
      return text as String;
    } catch (e) {
      print('❌ Gemini API error: $e');
      rethrow;
    }
  }

  /// Generate response with streaming (for typing effect)
  Stream<String> getChatResponseWithRAGStream({
    required String query,
    required String? collectionId,
  }) async* {
    try {
      // Get full response
      final fullResponse = await getChatResponseWithRAG(
        query: query,
        collectionId: collectionId,
      );
      
      // Stream it word by word for typing effect
      final words = fullResponse.split(' ');
      for (var i = 0; i < words.length; i++) {
        yield words.sublist(0, i + 1).join(' ');
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  /// Index collection articles to Qdrant for RAG
  Future<void> indexCollectionForRAG({
    required String collectionId,
    required List<ArticleModel> articles,
  }) async {
    try {
      print('📊 Indexing ${articles.length} articles for collection $collectionId');
      
      await _qdrantService.createCollectionKnowledgeBase(
        collectionId: collectionId,
        articles: articles,
        getEmbeddings: _hfService.getEmbeddings,
      );
      
      print('✅ Collection indexed successfully');
    } catch (e) {
      print('❌ Error indexing collection: $e');
      rethrow;
    }
  }

  /// Remove collection from Qdrant
  Future<void> removeCollectionIndex(String collectionId) async {
    try {
      await _qdrantService.deleteCollectionKnowledgeBase(collectionId);
      print('✅ Collection index removed');
    } catch (e) {
      print('❌ Error removing collection index: $e');
      rethrow;
    }
  }

  /// Check if collection is indexed
  Future<bool> isCollectionIndexed(String collectionId) async {
    try {
      final collectionName = 'collection_$collectionId';
      return await _qdrantService.collectionExists(collectionName);
    } catch (e) {
      return false;
    }
  }

  /// Index a single article for RAG context
  /// Creates a temporary collection for the article so AI can answer questions about it
  Future<void> indexArticleForRAG(ArticleModel article) async {
    try {
      print('📊 Indexing article for RAG: ${article.title}');
      
      // Create a unique collection ID for this article session
      final tempCollectionId = 'article_${article.id}';
      
      // Index the article
      await _qdrantService.createCollectionKnowledgeBase(
        collectionId: tempCollectionId,
        articles: [article],
        getEmbeddings: _hfService.getEmbeddings,
      );
      
      print('✅ Article indexed successfully for RAG');
    } catch (e) {
      print('⚠️ Error indexing article: $e (RAG will work without article context)');
      // Don't throw - we can still generate summary without RAG
    }
  }

  /// Generate article summary with RAG context
  /// Takes an article and returns a concise 2-3 sentence summary
  Future<String> getArticleSummary(ArticleModel article) async {
    try {
      print('📝 Generating summary for article: ${article.title}');
      
      // First, index the article for RAG
      await indexArticleForRAG(article);
      
      // Build content from article (use existing summary)
      final content = article.summary ?? 'No content available';
      
      final prompt = AIPromptsConfig.getArticleSummaryPrompt(
        title: article.title,
        source: article.source,
        content: content,
        author: article.author,
      );
      
      // Call Gemini API
      print('🔮 Calling Gemini API for summary...');
      final response = await _generateGeminiResponse(prompt);
      
      print('✅ Article summary generated successfully');
      return response;
    } catch (e) {
      print('❌ Error generating article summary: $e');
      return 'Sorry, I couldn\'t generate a summary for this article. Please try again.';
    }
  }

  /// Generate quick insight about an article (shorter than full summary)
  Future<String> getQuickInsight(ArticleModel article) async {
    try {
      print('💡 Generating quick insight for article: ${article.title}');
      
      final summary = article.summary ?? '';
      
      final prompt = AIPromptsConfig.getQuickInsightPrompt(
        title: article.title,
        source: article.source,
        summary: summary,
      );
      
      // Call Gemini API
      final response = await _generateGeminiResponse(prompt);
      
      print('✅ Quick insight generated');
      return response;
    } catch (e) {
      print('❌ Error generating insight: $e');
      return 'This article discusses: ${article.title}';
    }
  }
}

