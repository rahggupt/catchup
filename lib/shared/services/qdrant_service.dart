import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/article_model.dart';

/// Service for Qdrant vector database operations
class QdrantService {
  final Dio _dio = Dio();
  static const String collectionName = 'articles';
  
  QdrantService() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.qdrantUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'api-key': AppConstants.qdrantApiKey,
      },
    );
  }

  /// Store article embedding in Qdrant
  Future<void> storeArticle({
    required String articleId,
    required List<double> embedding,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _dio.put(
        '/collections/$collectionName/points',
        data: {
          'points': [
            {
              'id': articleId,
              'vector': embedding,
              'payload': metadata,
            }
          ]
        },
      );
    } catch (e) {
      throw Exception('Failed to store article in Qdrant: $e');
    }
  }

  /// Search for similar articles using vector similarity
  Future<List<Map<String, dynamic>>> searchSimilar({
    required List<double> queryEmbedding,
    int limit = 5,
    String? collectionId,
  }) async {
    try {
      final filter = collectionId != null
          ? {
              'must': [
                {
                  'key': 'collection_id',
                  'match': {'value': collectionId}
                }
              ]
            }
          : null;

      final response = await _dio.post(
        '/collections/$collectionName/points/search',
        data: {
          'vector': queryEmbedding,
          'limit': limit,
          'with_payload': true,
          if (filter != null) 'filter': filter,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['result'] as List;
        return results.map((r) => r['payload'] as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search in Qdrant: $e');
    }
  }

  /// Delete article from Qdrant
  Future<void> deleteArticle(String articleId) async {
    try {
      await _dio.post(
        '/collections/$collectionName/points/delete',
        data: {
          'points': [articleId]
        },
      );
    } catch (e) {
      throw Exception('Failed to delete article from Qdrant: $e');
    }
  }

  /// Check collection exists
  Future<bool> collectionExists() async {
    try {
      final response = await _dio.get('/collections/$collectionName');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Create collection if it doesn't exist
  Future<void> ensureCollection() async {
    try {
      final exists = await collectionExists();
      if (!exists) {
        await _dio.put(
          '/collections/$collectionName',
          data: {
            'vectors': {
              'size': AppConstants.embeddingDimensions,
              'distance': 'Cosine',
            }
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to create collection in Qdrant: $e');
    }
  }
}

