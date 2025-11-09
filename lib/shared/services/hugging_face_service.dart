import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for Hugging Face Inference API
/// Used for generating embeddings for RAG
class HuggingFaceService {
  final String apiKey;
  static const String embeddingModel = 'sentence-transformers/all-MiniLM-L6-v2';
  
  HuggingFaceService({required this.apiKey});

  /// Generate embeddings for text using Hugging Face Inference API
  Future<List<double>> getEmbeddings(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/pipeline/feature-extraction/$embeddingModel'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': text,
          'options': {
            'wait_for_model': true,
          },
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get embeddings: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      // The response is a nested array, flatten it
      List<double> embeddings;
      if (data is List && data.isNotEmpty) {
        if (data[0] is List) {
          embeddings = List<double>.from(data[0].map((e) => e.toDouble()));
        } else {
          embeddings = List<double>.from(data.map((e) => e.toDouble()));
        }
      } else {
        throw Exception('Unexpected response format from Hugging Face');
      }
      
      print('✅ Generated embeddings: ${embeddings.length} dimensions');
      return embeddings;
    } catch (e) {
      print('❌ Error getting embeddings from Hugging Face: $e');
      rethrow;
    }
  }

  /// Batch generate embeddings for multiple texts
  Future<List<List<double>>> getBatchEmbeddings(List<String> texts) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/pipeline/feature-extraction/$embeddingModel'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': texts,
          'options': {
            'wait_for_model': true,
          },
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get batch embeddings: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      // Process batch response
      final embeddings = <List<double>>[];
      for (final item in data) {
        if (item is List) {
          if (item.isNotEmpty && item[0] is List) {
            embeddings.add(List<double>.from(item[0].map((e) => e.toDouble())));
          } else {
            embeddings.add(List<double>.from(item.map((e) => e.toDouble())));
          }
        }
      }
      
      print('✅ Generated batch embeddings for ${embeddings.length} texts');
      return embeddings;
    } catch (e) {
      print('❌ Error getting batch embeddings from Hugging Face: $e');
      rethrow;
    }
  }
}

