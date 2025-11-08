import 'gemini_service.dart';
import 'qdrant_service.dart';
import 'embedding_service.dart';
import '../models/article_model.dart';

/// Service for Retrieval-Augmented Generation (RAG)
class RAGService {
  final GeminiService _geminiService = GeminiService();
  final QdrantService _qdrantService = QdrantService();
  final EmbeddingService _embeddingService = EmbeddingService();

  /// Initialize RAG service
  Future<void> initialize() async {
    await _qdrantService.ensureCollection();
  }

  /// Index an article for RAG
  Future<void> indexArticle(ArticleModel article) async {
    try {
      // Generate embedding for the article
      final embedding = await _embeddingService.generateArticleEmbedding(
        title: article.title,
        summary: article.summary,
        content: article.content,
      );

      // Store in Qdrant with metadata
      await _qdrantService.storeArticle(
        articleId: article.id,
        embedding: embedding,
        metadata: {
          'id': article.id,
          'title': article.title,
          'summary': article.summary,
          'source': article.source,
          'author': article.author,
          'url': article.url,
          'topic': article.topic,
          'published_at': article.publishedAt?.toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to index article: $e');
    }
  }

  /// Query the knowledge base and generate AI response
  Future<Map<String, dynamic>> query({
    required String question,
    String? collectionId,
    int maxContextArticles = 5,
  }) async {
    try {
      // Generate embedding for the question
      final questionEmbedding = await _embeddingService.generateEmbedding(question);

      // Search for similar articles in Qdrant
      final similarArticles = await _qdrantService.searchSimilar(
        queryEmbedding: questionEmbedding,
        limit: maxContextArticles,
        collectionId: collectionId,
      );

      if (similarArticles.isEmpty) {
        return {
          'answer':
              'I don\'t have enough information in your collections to answer that question. Try adding more articles on this topic.',
          'citations': [],
        };
      }

      // Build context from similar articles
      final context = _buildContext(similarArticles);

      // Generate answer using Gemini with context
      final answer = await _geminiService.generateContent(
        prompt: question,
        context: context,
      );

      // Extract citations
      final citations = similarArticles.map((article) {
        return {
          'title': article['title'],
          'source': article['source'],
          'url': article['url'],
        };
      }).toList();

      return {
        'answer': answer,
        'citations': citations,
      };
    } catch (e) {
      throw Exception('Failed to process query: $e');
    }
  }

  /// Build context string from articles
  String _buildContext(List<Map<String, dynamic>> articles) {
    final buffer = StringBuffer();
    buffer.writeln('Based on the following articles from your collections:\n');

    for (var i = 0; i < articles.length; i++) {
      final article = articles[i];
      buffer.writeln('${i + 1}. "${article['title']}" from ${article['source']}');
      buffer.writeln('   ${article['summary']}');
      buffer.writeln();
    }

    buffer.writeln('\nPlease answer based on this information and cite sources:');
    return buffer.toString();
  }

  /// Delete article from index
  Future<void> deleteArticle(String articleId) async {
    await _qdrantService.deleteArticle(articleId);
  }

  /// Batch index multiple articles
  Future<void> indexArticles(List<ArticleModel> articles) async {
    for (final article in articles) {
      try {
        await indexArticle(article);
      } catch (e) {
        // Log error but continue with other articles
        print('Failed to index article ${article.id}: $e');
      }
    }
  }
}

