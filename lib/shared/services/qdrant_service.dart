import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

/// Service for Qdrant vector database operations
/// Used for RAG (Retrieval Augmented Generation) in AI chat
class QdrantService {
  final String apiUrl;
  final String apiKey;
  
  QdrantService({
    required this.apiUrl,
    required this.apiKey,
  });

  /// Create a collection in Qdrant for storing embeddings
  Future<void> createCollection(String collectionName) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/collections/$collectionName'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'vectors': {
            'size': 384, // Hugging Face 'sentence-transformers/all-MiniLM-L6-v2' dimension
            'distance': 'Cosine',
          },
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create collection: ${response.body}');
      }
      
      print('✅ Qdrant collection created: $collectionName');
    } catch (e) {
      print('❌ Error creating Qdrant collection: $e');
      rethrow;
    }
  }

  /// Delete a collection from Qdrant
  Future<void> deleteCollection(String collectionName) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/collections/$collectionName'),
        headers: {
          'api-key': apiKey,
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception('Failed to delete collection: ${response.body}');
      }
      
      print('✅ Qdrant collection deleted: $collectionName');
    } catch (e) {
      print('❌ Error deleting Qdrant collection: $e');
      rethrow;
    }
  }

  /// Add article embeddings to Qdrant collection
  Future<void> addArticleEmbeddings({
    required String collectionName,
    required String articleId,
    required List<double> embeddings,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/collections/$collectionName/points'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'points': [
            {
              'id': articleId,
              'vector': embeddings,
              'payload': metadata,
            }
          ],
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add embeddings: ${response.body}');
      }
      
      print('✅ Article embeddings added to Qdrant: $articleId');
    } catch (e) {
      print('❌ Error adding embeddings to Qdrant: $e');
      rethrow;
    }
  }

  /// Search for similar articles using query embeddings
  Future<List<Map<String, dynamic>>> searchSimilar({
    required String collectionName,
    required List<double> queryEmbeddings,
    int limit = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/collections/$collectionName/points/search'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'vector': queryEmbeddings,
          'limit': limit,
          'with_payload': true,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to search: ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      final results = (data['result'] as List).map((item) {
        return {
          'id': item['id'],
          'score': item['score'],
          'payload': item['payload'],
        };
      }).toList();
      
      print('✅ Found ${results.length} similar articles in Qdrant');
      return results;
    } catch (e) {
      print('❌ Error searching Qdrant: $e');
      rethrow;
    }
  }

  /// Create knowledge base for a collection by adding all articles
  Future<void> createCollectionKnowledgeBase({
    required String collectionId,
    required List<ArticleModel> articles,
    required Future<List<double>> Function(String text) getEmbeddings,
  }) async {
    try {
      final collectionName = 'collection_$collectionId';
      
      // Create the collection in Qdrant
      await createCollection(collectionName);
      
      // Add each article's embeddings
      for (final article in articles) {
        // Combine title and summary for better context
        final text = '${article.title}\n\n${article.summary}';
        final embeddings = await getEmbeddings(text);
        
        await addArticleEmbeddings(
          collectionName: collectionName,
          articleId: article.id,
          embeddings: embeddings,
          metadata: {
            'title': article.title,
            'summary': article.summary,
            'source': article.source,
            'url': article.url,
            'published_at': article.publishedAt?.toIso8601String(),
          },
        );
      }
      
      print('✅ Knowledge base created for collection: $collectionId');
    } catch (e) {
      print('❌ Error creating knowledge base: $e');
      rethrow;
    }
  }

  /// Query knowledge base for relevant context (RAG)
  Future<List<Map<String, dynamic>>> queryKnowledgeBase({
    required String collectionId,
    required String query,
    required Future<List<double>> Function(String text) getEmbeddings,
    int limit = 5,
  }) async {
    try {
      final collectionName = 'collection_$collectionId';
      
      // Get embeddings for the query
      final queryEmbeddings = await getEmbeddings(query);
      
      // Search for similar articles
      final results = await searchSimilar(
        collectionName: collectionName,
        queryEmbeddings: queryEmbeddings,
        limit: limit,
      );
      
      return results;
    } catch (e) {
      print('❌ Error querying knowledge base: $e');
      rethrow;
    }
  }

  /// Delete knowledge base for a collection
  Future<void> deleteCollectionKnowledgeBase(String collectionId) async {
    try {
      final collectionName = 'collection_$collectionId';
      await deleteCollection(collectionName);
      
      print('✅ Knowledge base deleted for collection: $collectionId');
    } catch (e) {
      print('❌ Error deleting knowledge base: $e');
      rethrow;
    }
  }

  /// Check if a collection exists in Qdrant
  Future<bool> collectionExists(String collectionName) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/collections/$collectionName'),
        headers: {
          'api-key': apiKey,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error checking collection existence: $e');
      return false;
    }
  }
}
