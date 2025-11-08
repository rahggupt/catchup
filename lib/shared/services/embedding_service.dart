import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// Service for generating embeddings using Hugging Face API
class EmbeddingService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api-inference.huggingface.co';
  
  EmbeddingService() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Authorization': 'Bearer ${AppConstants.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Generate embedding for text using HuggingFace model
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await _dio.post(
        '/models/${AppConstants.embeddingModel}',
        data: {
          'inputs': text,
        },
      );

      if (response.statusCode == 200) {
        // HuggingFace returns embedding directly
        if (response.data is List) {
          return (response.data as List).cast<double>();
        } else if (response.data is Map && response.data.containsKey('embeddings')) {
          return (response.data['embeddings'] as List).cast<double>();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Generate embeddings for multiple texts
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    try {
      final response = await _dio.post(
        '/models/${AppConstants.embeddingModel}',
        data: {
          'inputs': texts,
        },
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((e) => (e as List).cast<double>())
              .toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to generate embeddings: $e');
    }
  }

  /// Generate embedding for article (title + summary)
  Future<List<double>> generateArticleEmbedding({
    required String title,
    required String summary,
    String? content,
  }) async {
    final text = content != null
        ? '$title. $summary. ${content.substring(0, content.length > 500 ? 500 : content.length)}'
        : '$title. $summary';
    
    return await generateEmbedding(text);
  }
}

