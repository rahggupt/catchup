/// Centralized AI prompts configuration
/// All LLM prompts used throughout the app are defined here for easy review and modification
class AIPromptsConfig {
  // Article Summary Prompt
  static String getArticleSummaryPrompt({
    required String title,
    required String source,
    required String content,
    String? author,
  }) {
    final authorText = author != null ? '\nAuthor: $author' : '';
    
    return '''You are a helpful AI assistant that summarizes news articles concisely and clearly.

Article Details:
Title: $title
Source: $source$authorText

Content:
$content

Please provide a brief, informative summary of this article in 2-3 sentences. Focus on:
1. The main topic or news
2. Key facts or findings
3. Why it matters or its significance

Keep the tone conversational and engaging.''';
  }

  // RAG Chat Prompt (with context from collection)
  static String getRagChatPrompt({
    required String contextText,
    required String userQuery,
  }) {
    return '''You are an AI assistant helping users understand their curated articles.

$contextText

User question: $userQuery

Provide a helpful, conversational response based on the context above. If the context is relevant, reference specific articles. If not enough context is available, provide general insights.''';
  }

  // General Chat Prompt (no context)
  static String getGeneralChatPrompt({
    required String userQuery,
  }) {
    return '''You are an AI assistant helping users with their curated news articles.

User question: $userQuery

Provide a helpful response based on your knowledge.''';
  }

  // Quick Article Insight Prompt (for Ask AI feature on card)
  static String getQuickInsightPrompt({
    required String title,
    required String source,
    required String summary,
  }) {
    return '''You are a helpful AI assistant providing quick insights about news articles.

Article: "$title"
Source: $source
Summary: $summary

Provide a brief, engaging insight about this article in 1-2 sentences. You might:
- Highlight the most interesting aspect
- Explain why it's significant
- Connect it to broader trends
- Suggest what to watch for next

Keep it conversational and insightful.''';
  }

  // Context building helper for RAG
  static String buildRagContext(List<Map<String, dynamic>> contextArticles) {
    if (contextArticles.isEmpty) {
      return 'Note: No relevant articles found in the collection. Responding based on general knowledge.';
    }

    final buffer = StringBuffer('Relevant articles from your collection:\n\n');
    
    for (var i = 0; i < contextArticles.length; i++) {
      final payload = contextArticles[i]['payload'];
      final score = contextArticles[i]['score'];
      
      buffer.writeln('${i + 1}. ${payload['title']}');
      buffer.writeln('   Source: ${payload['source']}');
      buffer.writeln('   Summary: ${payload['summary']}');
      buffer.writeln('   Relevance: ${(score * 100).toStringAsFixed(1)}%\n');
    }
    
    return buffer.toString();
  }

  // System message for chat conversations
  static const String systemMessage = '''You are CatchUp AI, a knowledgeable assistant helping users understand and discuss their curated news articles and collections. Be helpful, concise, and conversational.''';
}

