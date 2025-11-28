import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import 'logger_service.dart';

/// Service for Perplexity AI API integration
/// Provides access to Perplexity's online LLM with real-time web knowledge
class PerplexityService {
  final LoggerService _logger = LoggerService();
  final String? customApiKey;
  
  static const String _baseUrl = 'https://api.perplexity.ai';
  
  PerplexityService({this.customApiKey});
  
  /// Generate a response using Perplexity AI
  /// Combines RAG context with Perplexity's web knowledge
  Future<String> generateResponse({
    required String prompt,
    List<String>? ragContext,
    String? systemPrompt,
  }) async {
    try {
      final apiKey = customApiKey ?? AppConstants.perplexityApiKey;
      
      if (apiKey.isEmpty) {
        _logger.error('Perplexity API key not configured', category: 'AI');
        throw Exception('Perplexity API key not configured');
      }
      
      _logger.info('Calling Perplexity API', category: 'AI');
      
      // Build the enhanced prompt with RAG context
      String enhancedPrompt = prompt;
      if (ragContext != null && ragContext.isNotEmpty) {
        final contextStr = ragContext.join('\n\n---\n\n');
        enhancedPrompt = '''
Here are some relevant saved articles for context:

$contextStr

---

Based on the above context and your real-time web knowledge, please answer:

$prompt
''';
      }
      
      // Build messages
      final messages = <Map<String, String>>[];
      
      if (systemPrompt != null) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': enhancedPrompt,
      });
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.perplexityModel,
          'messages': messages,
          'temperature': AppConstants.temperature,
          'max_tokens': AppConstants.maxTokens,
        }),
      ).timeout(AppConstants.apiTimeout);
      
      if (response.statusCode != 200) {
        _logger.error('Perplexity API error: ${response.statusCode}', 
          category: 'AI', error: response.body);
        throw Exception('Perplexity API error: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      
      if (data['choices'] == null || (data['choices'] as List).isEmpty) {
        _logger.error('No response from Perplexity', category: 'AI', error: data);
        throw Exception('No response from Perplexity API');
      }
      
      final text = data['choices'][0]['message']['content'] as String;
      
      _logger.success('Perplexity response received (${text.length} chars)', category: 'AI');
      
      return text;
    } catch (e, stackTrace) {
      _logger.error('Failed to get Perplexity response', 
        category: 'AI', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Get a summary of an article using Perplexity
  Future<String> summarizeArticle({
    required String title,
    required String content,
    String? url,
  }) async {
    try {
      _logger.info('Generating Perplexity summary for: $title', category: 'AI');
      
      final prompt = '''
Please provide a concise 2-3 paragraph summary of the following article:

Title: $title
${url != null ? 'URL: $url' : ''}

Content:
$content

Focus on the key points, main arguments, and important takeaways.
''';
      
      final summary = await generateResponse(
        prompt: prompt,
        systemPrompt: 'You are a helpful assistant that provides clear and concise summaries of articles.',
      );
      
      _logger.success('Article summary generated', category: 'AI');
      return summary;
    } catch (e, stackTrace) {
      _logger.error('Failed to summarize article', 
        category: 'AI', error: e, stackTrace: stackTrace);
      return 'Sorry, I couldn\'t generate a summary. Please try again.';
    }
  }
  
  /// Get a quick insight about an article using Perplexity
  Future<String> getQuickInsight({
    required String title,
    required String summary,
  }) async {
    try {
      _logger.info('Generating Perplexity quick insight', category: 'AI');
      
      final prompt = '''
Provide a 1-2 sentence key insight or takeaway from this article:

Title: $title
Summary: $summary

What's the most important thing readers should know?
''';
      
      final insight = await generateResponse(
        prompt: prompt,
        systemPrompt: 'You are a helpful assistant that identifies key insights from articles.',
      );
      
      _logger.success('Quick insight generated', category: 'AI');
      return insight;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate quick insight', 
        category: 'AI', error: e, stackTrace: stackTrace);
      return 'Unable to generate insight at this time.';
    }
  }
  
  /// Answer a question using Perplexity with RAG context
  Future<String> answerQuestionWithRAG({
    required String question,
    required List<String> ragContext,
  }) async {
    try {
      _logger.info('Answering question with Perplexity + RAG', category: 'AI');
      
      final answer = await generateResponse(
        prompt: question,
        ragContext: ragContext,
        systemPrompt: '''
You are an AI assistant helping users understand their saved articles.

IMPORTANT RULES:
1. ONLY answer based on the articles provided in the context
2. If the question cannot be answered from the provided articles, respond with: "This question is outside the scope of the articles in this collection. I can only answer questions about the content you've saved."
3. Do NOT use general web knowledge or information outside the provided articles
4. Always reference which article you're using when answering
5. Be concise and conversational

Your role is to help users understand their saved content, not to provide general information from the web.
''',
      );
      
      _logger.success('Question answered successfully', category: 'AI');
      return answer;
    } catch (e, stackTrace) {
      _logger.error('Failed to answer question', 
        category: 'AI', error: e, stackTrace: stackTrace);
      return 'Sorry, I encountered an error. Please try again.';
    }
  }
  
  /// Check if Perplexity is configured
  bool isConfigured() {
    final apiKey = customApiKey ?? AppConstants.perplexityApiKey;
    return apiKey.isNotEmpty;
  }
}

