import 'dart:convert';
import 'package:http/http.dart' as http;
import 'qdrant_service.dart';
import 'hugging_face_service.dart';
import '../models/article_model.dart';

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
            contextText = 'Relevant articles from your collection:\n\n';
            for (var i = 0; i < context.length; i++) {
              final payload = context[i]['payload'];
              final score = context[i]['score'];
              contextText += '${i + 1}. ${payload['title']}\n';
              contextText += '   Source: ${payload['source']}\n';
              contextText += '   Summary: ${payload['summary']}\n';
              contextText += '   Relevance: ${(score * 100).toStringAsFixed(1)}%\n\n';
            }
          }
        }
      }
      
      // Build prompt with context
      final prompt = contextText.isNotEmpty
          ? '''You are an AI assistant helping users understand their curated articles.

$contextText

User question: $query

Provide a helpful, conversational response based on the context above. If the context is relevant, reference specific articles. If not enough context is available, provide general insights.'''
          : '''You are an AI assistant helping users with their curated news articles.

User question: $query

Provide a helpful response based on your knowledge.''';
      
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
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey'),
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
}

