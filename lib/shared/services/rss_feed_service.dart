import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/article_model.dart';

/// Service for fetching and parsing RSS feeds
class RssFeedService {
  // CORS proxy for web browsers (allorigins.win is a free CORS proxy)
  static const String corsProxy = 'https://api.allorigins.win/raw?url=';
  
  /// Get the URL with CORS proxy if running on web
  String _getCorsProxyUrl(String url) {
    if (kIsWeb) {
      // Use CORS proxy for web
      return '$corsProxy${Uri.encodeComponent(url)}';
    }
    // Direct URL for mobile/desktop
    return url;
  }
  
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
  /// Accepts optional [customFeedUrl] for user-added sources
  Future<List<ArticleModel>> fetchFromSource(String sourceName, {int limit = 5, String? customFeedUrl}) async {
    print('🔍 RSS: START fetchFromSource for $sourceName');
    print('📌 RSS: customFeedUrl from DB = "$customFeedUrl"');
    print('📌 RSS: hardcoded URL = "${rssFeedUrls[sourceName]}"');
    
    // Validate custom URL - must be a full URL starting with http(s)
    final isValidUrl = customFeedUrl != null && 
                       customFeedUrl.isNotEmpty && 
                       (customFeedUrl.startsWith('http://') || customFeedUrl.startsWith('https://'));
    
    print('🔍 RSS: URL validation - isValidUrl = $isValidUrl');
    if (customFeedUrl != null && customFeedUrl.isNotEmpty && !isValidUrl) {
      print('⚠️ RSS: Invalid URL format (missing http/https): "$customFeedUrl"');
      print('⚠️ RSS: Falling back to hardcoded URL');
    }
    
    final feedUrl = isValidUrl ? customFeedUrl : rssFeedUrls[sourceName];
        
    if (feedUrl == null || feedUrl.isEmpty) {
      print('❌ RSS: No feed URL configured for: $sourceName');
      print('❌ RSS: customFeedUrl valid: $isValidUrl');
      print('❌ RSS: hardcoded URL exists: ${rssFeedUrls[sourceName] != null}');
      return [];
    }

    print('✅ RSS: Using URL = $feedUrl');
    print('📊 RSS: Limit = $limit, Source = ${isValidUrl ? "Database (valid)" : "Hardcoded (fallback)"}');

    try {
      // Use CORS proxy for web, direct URL for mobile
      final requestUrl = _getCorsProxyUrl(feedUrl);
      if (kIsWeb) {
        print('🌐 RSS: Using CORS proxy for web');
      }
      
      print('⏳ RSS: Fetching from network...');
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: kIsWeb ? {} : {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 RSS: Response status = ${response.statusCode}');
      print('📏 RSS: Response body length = ${response.body.length} bytes');

      if (response.statusCode != 200) {
        print('❌ RSS: HTTP error ${response.statusCode} for $sourceName');
        return [];
      }

      print('🔄 RSS: Parsing XML feed...');
      
      // Parse RSS feed
      final feed = RssFeed.parse(response.body);
      
      print('✅ RSS: Feed parsed successfully');
      print('📰 RSS: Feed title = ${feed.title}');
      print('📝 RSS: Total items in feed = ${feed.items?.length ?? 0}');
      
      final articles = <ArticleModel>[];

      // Take only the specified limit (default 5, sorted by latest)
      final items = (feed.items ?? []).take(limit).toList();
      print('📦 RSS: Processing first ${items.length} items (limit=$limit)');
      
      int parsedCount = 0;
      int skippedCount = 0;
      
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        try {
          print('  📄 RSS: Item ${i + 1}/${items.length}:');
          print('    Title: ${item.title?.substring(0, item.title!.length.clamp(0, 50))}...');
          print('    Link: ${item.link}');
          print('    Has description: ${item.description != null && item.description!.isNotEmpty}');
          
          final article = _parseRssItem(item, sourceName);
          if (article != null) {
            articles.add(article);
            parsedCount++;
            print('    ✅ Parsed successfully');
          } else {
            skippedCount++;
            print('    ⚠️ Skipped (null result from parser)');
          }
        } catch (e) {
          skippedCount++;
          print('    ❌ Error parsing: $e');
        }
      }

      print('✅ RSS: Complete! Parsed=$parsedCount, Skipped=$skippedCount, Total=$parsedCount');
      return articles;
      
    } catch (e, stackTrace) {
      print('❌ RSS: Exception for $sourceName: $e');
      print('Stack trace: $stackTrace');
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
    allArticles.sort((a, b) => (b.publishedAt ?? DateTime.now()).compareTo(a.publishedAt ?? DateTime.now()));
    
    print('Total articles fetched: ${allArticles.length}');
    return allArticles;
  }

  /// Parse an RSS item into an ArticleModel
  ArticleModel? _parseRssItem(RssItem item, String source) {
    print('      🔍 _parseRssItem: title exists=${item.title != null}, link exists=${item.link != null}');
    
    final title = item.title?.trim();
    final link = item.link?.trim();
    
    if (title == null || title.isEmpty) {
      print('      ❌ _parseRssItem: REJECTED - title is null/empty');
      return null;
    }
    
    if (link == null || link.isEmpty) {
      print('      ❌ _parseRssItem: REJECTED - link is null/empty');
      return null;
    }
    
    print('      ✅ _parseRssItem: Title and link OK, continuing...');

    // Extract description (remove HTML tags and decode entities)
    var description = _stripHtml(item.description ?? '');
    
    // If description is too short, try to get content
    if (description.length < 100 && item.content?.value != null) {
      final content = _stripHtml(item.content!.value!);
      if (content.length > description.length) {
        description = content;
      }
    }
    
    // Parse published date with multiple fallback strategies
    DateTime? publishedAt;

    // Strategy 1: Try item.pubDate
    if (item.pubDate != null) {
      try {
        publishedAt = item.pubDate as DateTime;
        print('      📅 Date parsed from pubDate: $publishedAt');
      } catch (e) {
        print('      ⚠️ Failed to parse pubDate: $e');
      }
    }

    // Strategy 2: Try dc:date if pubDate failed
    if (publishedAt == null && item.dc?.date != null) {
      try {
        publishedAt = DateTime.parse(item.dc!.date!);
        print('      📅 Date parsed from dc:date: $publishedAt');
      } catch (e) {
        print('      ⚠️ Failed to parse dc:date: $e');
      }
    }

    // Strategy 3: Check if it's in the future (bad date)
    if (publishedAt != null && publishedAt.isAfter(DateTime.now())) {
      print('      ⚠️ Date is in the future, ignoring: $publishedAt');
      publishedAt = null;
    }

    // Strategy 4: As last resort, use createdAt (now) but log it
    if (publishedAt == null) {
      publishedAt = DateTime.now();
      print('      ⚠️ WARNING: No valid date found, using current time');
      print('      📰 Article: ${title.substring(0, title.length.clamp(0, 50))}');
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
      createdAt: DateTime.now(),
    );
  }

  /// Strip HTML tags from text and decode HTML entities
  String _stripHtml(String html) {
    final regExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    var text = html.replaceAll(regExp, '').trim();
    
    // Decode common HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#8230;', '...')
        .replaceAll('&hellip;', '...')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"');
    
    // Decode numeric entities
    final numericEntityRegex = RegExp(r'&#(\d+);');
    text = text.replaceAllMapped(numericEntityRegex, (match) {
      try {
        final charCode = int.parse(match.group(1)!);
        return String.fromCharCode(charCode);
      } catch (e) {
        return match.group(0)!;
      }
    });
    
    return text.trim();
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
        print('Found media content URL: $mediaUrl');
        return mediaUrl;
      }
    }

    // Try enclosure
    if (item.enclosure?.url != null && item.enclosure!.url!.isNotEmpty) {
      print('Found enclosure URL: ${item.enclosure!.url}');
      return item.enclosure!.url!;
    }

    // Try media:thumbnail
    if (item.media?.thumbnails?.isNotEmpty ?? false) {
      final thumbUrl = item.media!.thumbnails!.first.url;
      if (thumbUrl != null && thumbUrl.isNotEmpty) {
        print('Found thumbnail URL: $thumbUrl');
        return thumbUrl;
      }
    }
    
    // Try to extract image from description/content
    final description = item.description ?? item.content?.value ?? '';
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegex.firstMatch(description);
    if (match != null && match.group(1) != null) {
      final imgUrl = match.group(1)!;
      print('Found image in description: $imgUrl');
      return imgUrl;
    }

    // Use source-specific placeholder
    print('No image found, using placeholder');
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
    // Generate a valid UUID from URL hash
    // Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (UUID v4 format)
    final hash = url.hashCode.abs();
    final hex = hash.toRadixString(16).padLeft(12, '0');
    
    // Create deterministic but valid UUID from hash
    // Ensure we have enough characters by duplicating and taking substrings
    final fullHex = (hex + hex + hex).substring(0, 32);
    
    // Format as UUID v4: 8-4-4-4-12
    return '${fullHex.substring(0, 8)}-${fullHex.substring(8, 12)}-4${fullHex.substring(13, 16)}-${fullHex.substring(16, 20)}-${fullHex.substring(20, 32)}';
  }
}

