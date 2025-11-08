import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// Service for Google Gemini API integration
class GeminiService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  GeminiService() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  /// Generate content using Gemini
  Future<String> generateContent({
    required String prompt,
    String? context,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final fullPrompt = context != null 
          ? 'Context: $context\n\nQuestion: $prompt'
          : prompt;

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
      }

      throw Exception('Failed to generate content');
    } catch (e) {
      throw Exception('Gemini API error: $e');
    }
  }

  /// Generate streaming response
  Stream<String> generateContentStream({
    required String prompt,
    String? context,
  }) async* {
    try {
      final fullPrompt = context != null 
          ? 'Context: $context\n\nQuestion: $prompt'
          : prompt;

      final response = await _dio.post(
        '/models/gemini-1.5-flash:streamGenerateContent?key=${AppConstants.geminiApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      if (response.data is Stream) {
        await for (final chunk in response.data) {
          yield String.fromCharCodes(chunk);
        }
      }
    } catch (e) {
      throw Exception('Gemini streaming error: $e');
    }
  }
}

