import 'dart:convert';
import 'package:http/http.dart' as http;
import 'qdrant_service.dart';
import 'hugging_face_service.dart';
import 'logger_service.dart';
import 'perplexity_service.dart';
import '../models/article_model.dart';
import '../../core/config/ai_prompts_config.dart';
import '../../core/constants/app_constants.dart';

/// Service for AI chat with RAG (Retrieval Augmented Generation)
/// Supports multiple AI providers: Gemini and Perplexity
class AIService {
  final LoggerService _logger = LoggerService();
  final String geminiApiKey;
  final QdrantService _qdrantService;
  final HuggingFaceService _hfService;
  final PerplexityService _perplexityService;
  String aiProvider; // Current AI provider ('gemini' or 'perplexity')
  
  AIService({
    required this.geminiApiKey,
    required String qdrantUrl,
    required String qdrantKey,
    required String huggingFaceKey,
    this.aiProvider = 'gemini',
  }) : _qdrantService = QdrantService(apiUrl: qdrantUrl, apiKey: qdrantKey),
       _hfService = HuggingFaceService(apiKey: huggingFaceKey),
       _perplexityService = PerplexityService();

  /// Generate AI response with RAG context from collection
  Future<String> getChatResponseWithRAG({
    required String query,
    required String? collectionId,
  }) async {
    try {
      _logger.info('Processing AI query with RAG: $query', category: 'AI');
      
      String contextText = '';
      
      // If collection is specified, get RAG context
      if (collectionId != null && collectionId != 'all_sources') {
        _logger.info('Fetching RAG context from collection: $collectionId', category: 'AI');
        
        // Check if collection exists in Qdrant
        final collectionName = 'collection_$collectionId';
        final exists = await _qdrantService.collectionExists(collectionName);
        
        if (!exists) {
          _logger.warning('Collection not indexed in Qdrant: $collectionId', category: 'AI');
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
            _logger.info('Retrieved ${context.length} context items from RAG', category: 'AI');
            contextText = AIPromptsConfig.buildRagContext(context);
          }
        }
      }
      
      // Generate response using selected AI provider
      _logger.info('Using AI provider: $aiProvider', category: 'AI');
      final response = await _generateAIResponse(query, contextText);
      
      _logger.success('AI response generated successfully', category: 'AI');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate AI response', category: 'AI', error: e, stackTrace: stackTrace);
      return 'Sorry, I encountered an error processing your request. Please try again.';
    }
  }
  
  /// Generate AI response using the selected provider
  Future<String> _generateAIResponse(String query, String contextText) async {
    if (aiProvider == 'perplexity' && _perplexityService.isConfigured()) {
      // Use Perplexity with RAG context
      if (contextText.isNotEmpty) {
        // Extract just the article content from the context
        final ragContextList = contextText.split('\n\n---\n\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        return await _perplexityService.answerQuestionWithRAG(
          question: query,
          ragContext: ragContextList,
        );
      } else {
        // Use Perplexity without RAG context
        return await _perplexityService.generateResponse(
          prompt: query,
          systemPrompt: 'You are a knowledgeable assistant helping users understand articles and topics.',
        );
      }
    } else {
      // Default to Gemini
      final prompt = contextText.isNotEmpty
          ? AIPromptsConfig.getRagChatPrompt(
              contextText: contextText,
              userQuery: query,
            )
          : AIPromptsConfig.getGeneralChatPrompt(
              userQuery: query,
            );
      
      return await _generateGeminiResponse(prompt);
    }
  }

  /// Generate response using Gemini API
  Future<String> _generateGeminiResponse(String prompt) async {
    try {
      _logger.info('Calling Gemini 2.0 Flash API', category: 'AI');
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
        _logger.error('Gemini API error: ${response.statusCode}', category: 'AI', error: response.body);
        throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      
      _logger.success('Gemini API response received', category: 'AI');
      return text as String;
    } catch (e, stackTrace) {
      _logger.error('Gemini API call failed', category: 'AI', error: e, stackTrace: stackTrace);
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
      _logger.info('Generating summary for article: ${article.title}', category: 'AI');
      
      // First, index the article for RAG
      await indexArticleForRAG(article);
      
      // Build content from article (use existing summary)
      final content = article.summary ?? 'No content available';
      
      // Generate summary using selected provider
      _logger.info('Using AI provider: $aiProvider', category: 'AI');
      
      String response;
      if (aiProvider == 'perplexity' && _perplexityService.isConfigured()) {
        response = await _perplexityService.summarizeArticle(
          title: article.title,
          content: content,
          url: article.url,
        );
      } else {
        // Use Gemini
        final prompt = AIPromptsConfig.getArticleSummaryPrompt(
          title: article.title,
          source: article.source,
          content: content,
          author: article.author,
        );
        response = await _generateGeminiResponse(prompt);
      }
      
      _logger.success('Article summary generated successfully', category: 'AI');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate article summary: ${article.title}', category: 'AI', error: e, stackTrace: stackTrace);
      return 'Sorry, I couldn\'t generate a summary for this article. Please try again.';
    }
  }

  /// Generate quick insight about an article (shorter than full summary)
  Future<String> getQuickInsight(ArticleModel article) async {
    try {
      _logger.info('Generating quick insight for article: ${article.title}', category: 'AI');
      
      final summary = article.summary ?? '';
      
      String response;
      if (aiProvider == 'perplexity' && _perplexityService.isConfigured()) {
        response = await _perplexityService.getQuickInsight(
          title: article.title,
          summary: summary,
        );
      } else {
        // Use Gemini
        final prompt = AIPromptsConfig.getQuickInsightPrompt(
          title: article.title,
          source: article.source,
          summary: summary,
        );
        response = await _generateGeminiResponse(prompt);
      }
      
      _logger.success('Quick insight generated', category: 'AI');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate quick insight: ${article.title}', category: 'AI', error: e, stackTrace: stackTrace);
      return 'This article discusses: ${article.title}';
    }
  }
}

