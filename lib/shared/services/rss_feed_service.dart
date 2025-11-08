import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../models/article_model.dart';

/// Service for fetching and parsing RSS feeds
class RssFeedService {
  
  // RSS Feed URLs for each source
  static const Map<String, String> rssFeedUrls = {
    'Wired': 'https://www.wired.com/feed/rss',
    'TechCrunch': 'https://techcrunch.com/feed/',
    'MIT Tech Review': 'https://www.technologyreview.com/feed/',
    'The Guardian': 'https://www.theguardian.com/technology/rss',
    'BBC Science': 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml',
    'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/index',
    'The Verge': 'https://www.theverge.com/rss/index.xml',
  };

  /// Fetch articles from a single RSS feed
  Future<List<ArticleModel>> fetchFromSource(String sourceName) async {
    final feedUrl = rssFeedUrls[sourceName];
    if (feedUrl == null) {
      print('No RSS feed URL for source: $sourceName');
      return [];
    }

    try {
      print('Fetching RSS feed for $sourceName from $feedUrl');
      
      final response = await http.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Failed to fetch $sourceName: ${response.statusCode}');
        return [];
      }

      // Parse RSS feed
      final feed = RssFeed.parse(response.body);
      final articles = <ArticleModel>[];

      for (var item in feed.items ?? []) {
        try {
          final article = _parseRssItem(item, sourceName);
          if (article != null) {
            articles.add(article);
          }
        } catch (e) {
          print('Error parsing RSS item from $sourceName: $e');
        }
      }

      print('Fetched ${articles.length} articles from $sourceName');
      return articles;
      
    } catch (e) {
      print('Error fetching RSS feed for $sourceName: $e');
      return [];
    }
  }

  /// Fetch articles from multiple sources in parallel
  Future<List<ArticleModel>> fetchFromSources(List<String> sourceNames) async {
    print('Fetching from ${sourceNames.length} sources in parallel');
    
    // Fetch all sources simultaneously
    final futures = sourceNames.map((source) => fetchFromSource(source)).toList();
    final results = await Future.wait(futures);
    
    // Combine all articles
    final allArticles = <ArticleModel>[];
    for (var articles in results) {
      allArticles.addAll(articles);
    }
    
    // Sort by published date (newest first)
    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    print('Total articles fetched: ${allArticles.length}');
    return allArticles;
  }

  /// Parse an RSS item into an ArticleModel
  ArticleModel? _parseRssItem(RssItem item, String source) {
    final title = item.title?.trim();
    final link = item.link?.trim();
    
    if (title == null || title.isEmpty || link == null || link.isEmpty) {
      return null;
    }

    // Extract description (remove HTML tags)
    final description = _stripHtml(item.description ?? '');
    
    // Parse date
    DateTime publishedAt;
    try {
      publishedAt = item.pubDate ?? DateTime.now();
    } catch (e) {
      publishedAt = DateTime.now();
    }

    // Extract author
    final author = item.author ?? item.dc?.creator ?? 'Staff Writer';

    // Extract topic from content
    final topic = _extractTopic(title, description, item.categories?.map((c) => c.value ?? '').toList());

    // Get image URL
    final imageUrl = _extractImageUrl(item, source);

    // Generate a unique ID from URL
    final id = _generateIdFromUrl(link);

    return ArticleModel(
      id: id,
      title: title.length > 200 ? title.substring(0, 200) : title,
      summary: description.length > 500 ? description.substring(0, 500) : description,
      source: source,
      author: author.length > 100 ? author.substring(0, 100) : author,
      topic: topic,
      url: link,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
    );
  }

  /// Strip HTML tags from text
  String _stripHtml(String html) {
    final regExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(regExp, '').trim();
  }

  /// Extract topic from title, description, and categories
  String _extractTopic(String title, String description, List<String>? categories) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    final cats = categories?.join(' ').toLowerCase() ?? '';

    if (text.contains('ai') || text.contains('artificial intelligence') || 
        text.contains('machine learning') || cats.contains('ai')) {
      return '#AI';
    }
    if (text.contains('climate') || text.contains('environment') || 
        text.contains('carbon') || cats.contains('climate')) {
      return '#Climate';
    }
    if (text.contains('space') || text.contains('mars') || 
        text.contains('nasa') || cats.contains('space')) {
      return '#Science';
    }
    if (text.contains('policy') || text.contains('regulation') || 
        text.contains('government') || cats.contains('politics')) {
      return '#Politics';
    }
    if (text.contains('startup') || text.contains('funding') || 
        text.contains('investment') || cats.contains('business')) {
      return '#Business';
    }
    if (text.contains('crypto') || text.contains('blockchain') || 
        text.contains('bitcoin') || cats.contains('crypto')) {
      return '#Crypto';
    }
    
    return '#Tech';
  }

  /// Extract image URL from RSS item
  String _extractImageUrl(RssItem item, String source) {
    // Try media:content first
    if (item.media?.contents?.isNotEmpty ?? false) {
      final mediaUrl = item.media!.contents!.first.url;
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        return mediaUrl;
      }
    }

    // Try enclosure
    if (item.enclosure?.url != null) {
      return item.enclosure!.url!;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails?.isNotEmpty ?? false) {
      final thumbUrl = item.media!.thumbnails!.first.url;
      if (thumbUrl != null && thumbUrl.isNotEmpty) {
        return thumbUrl;
      }
    }

    // Use source-specific placeholder
    return _getPlaceholderImage(source);
  }

  /// Get placeholder image for source
  String _getPlaceholderImage(String source) {
    const images = {
      'Wired': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
      'TechCrunch': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
      'MIT Tech Review': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80',
      'The Guardian': 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&q=80',
      'BBC Science': 'https://images.unsplash.com/photo-1614728423169-3f65fd722b7e?w=800&q=80',
      'Ars Technica': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800&q=80',
      'The Verge': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80',
    };
    return images[source] ?? 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&q=80';
  }

  /// Generate consistent ID from URL
  String _generateIdFromUrl(String url) {
    // Use a simple hash of the URL as the ID
    return url.hashCode.abs().toString();
  }
}

