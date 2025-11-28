# URL Scraping Implementation Guide

## Overview

This guide explains how to expand CatchUp beyond RSS feeds to support:
1. Direct URL imports (one-time article addition)
2. Website monitoring (periodic scraping of specific pages)
3. Social media links (Twitter, LinkedIn posts)
4. PDF/document parsing

## Current Architecture

**RSS-Only Flow**:
```
RSS Feed URL → rss_feed_provider.dart → Parse XML → Store Articles → Display
```

**New Flow**:
```
Any URL → Parse Metadata → Extract Content → Store Article → Display
```

## Implementation Plan

### Phase 1: URL Metadata Extraction (Quick Win - 4 hours)

#### 1.1 Add "Add Article by URL" Feature

**UI Changes**:

File: `lib/features/sources/presentation/screens/sources_screen.dart`

Add a new button/tab option:
```dart
Row(
  children: [
    ElevatedButton.icon(
      icon: Icon(Icons.rss_feed),
      label: Text('Add RSS Feed'),
      onPressed: () => _showAddRssDialog(),
    ),
    SizedBox(width: 12),
    OutlinedButton.icon(
      icon: Icon(Icons.link),
      label: Text('Add Article URL'),
      onPressed: () => _showAddUrlDialog(),
    ),
  ],
)
```

**Dialog Implementation**:
```dart
Future<void> _showAddUrlDialog() async {
  final urlController = TextEditingController();
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add Article from URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'Article URL',
              hintText: 'https://example.com/article',
            ),
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 8),
          Text(
            'Paste any article URL to add it to your collection',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = urlController.text.trim();
            if (url.isNotEmpty) {
              await _addArticleFromUrl(url);
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    ),
  );
}
```

#### 1.2 Create URL Parsing Service

**File**: `lib/shared/services/url_parser_service.dart`

```dart
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

class UrlParserService {
  final LoggerService _logger = LoggerService();
  
  /// Parse article metadata from URL
  Future<ArticleMetadata?> parseUrl(String url) async {
    try {
      _logger.info('Parsing URL: $url', category: 'UrlParser');
      
      // Fetch HTML
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL: ${response.statusCode}');
      }
      
      final document = html_parser.parse(response.body);
      
      // Extract Open Graph and Twitter Card metadata
      final metadata = ArticleMetadata(
        url: url,
        title: _extractTitle(document),
        description: _extractDescription(document),
        imageUrl: _extractImage(document, url),
        author: _extractAuthor(document),
        publishedDate: _extractPublishDate(document),
        source: _extractSource(url),
      );
      
      _logger.success('URL parsed successfully', category: 'UrlParser');
      return metadata;
    } catch (e, stackTrace) {
      _logger.error('Failed to parse URL', 
        category: 'UrlParser', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  String _extractTitle(Document doc) {
    // Try Open Graph title
    var title = doc.querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    
    // Try Twitter Card title
    title ??= doc.querySelector('meta[name="twitter:title"]')
        ?.attributes['content'];
    
    // Try standard title tag
    title ??= doc.querySelector('title')?.text;
    
    return title?.trim() ?? 'Untitled';
  }
  
  String _extractDescription(Document doc) {
    // Try Open Graph description
    var desc = doc.querySelector('meta[property="og:description"]')
        ?.attributes['content'];
    
    // Try Twitter Card description
    desc ??= doc.querySelector('meta[name="twitter:description"]')
        ?.attributes['content'];
    
    // Try meta description
    desc ??= doc.querySelector('meta[name="description"]')
        ?.attributes['content'];
    
    return desc?.trim() ?? '';
  }
  
  String? _extractImage(Document doc, String baseUrl) {
    // Try Open Graph image
    var imageUrl = doc.querySelector('meta[property="og:image"]')
        ?.attributes['content'];
    
    // Try Twitter Card image
    imageUrl ??= doc.querySelector('meta[name="twitter:image"]')
        ?.attributes['content'];
    
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      // Convert relative URL to absolute
      final uri = Uri.parse(baseUrl);
      imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
    }
    
    return imageUrl;
  }
  
  String? _extractAuthor(Document doc) {
    // Try Open Graph author
    var author = doc.querySelector('meta[property="article:author"]')
        ?.attributes['content'];
    
    // Try standard author meta tag
    author ??= doc.querySelector('meta[name="author"]')
        ?.attributes['content'];
    
    return author?.trim();
  }
  
  DateTime? _extractPublishDate(Document doc) {
    // Try Open Graph published time
    var dateStr = doc.querySelector('meta[property="article:published_time"]')
        ?.attributes['content'];
    
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  String _extractSource(String url) {
    final uri = Uri.parse(url);
    return uri.host.replaceAll('www.', '');
  }
}

class ArticleMetadata {
  final String url;
  final String title;
  final String description;
  final String? imageUrl;
  final String? author;
  final DateTime? publishedDate;
  final String source;
  
  ArticleMetadata({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
    this.author,
    this.publishedDate,
    required this.source,
  });
}
```

#### 1.3 Add URL Parsing to Supabase Service

**File**: `lib/shared/services/supabase_service.dart`

Add new method:
```dart
/// Add article from URL by parsing metadata
Future<String> addArticleFromUrl(String url, String userId) async {
  try {
    _logger.info('Adding article from URL: $url', category: 'Database');
    
    // Parse URL metadata
    final parser = UrlParserService();
    final metadata = await parser.parseUrl(url);
    
    if (metadata == null) {
      throw Exception('Failed to parse article from URL');
    }
    
    // Check if article already exists
    final existing = await _client
        .from('articles')
        .select('id')
        .eq('url', url)
        .maybeSingle();
    
    if (existing != null) {
      _logger.info('Article already exists', category: 'Database');
      return existing['id'] as String;
    }
    
    // Insert article
    final response = await _client
        .from('articles')
        .insert({
          'title': metadata.title,
          'summary': metadata.description,
          'url': metadata.url,
          'source': metadata.source,
          'topic': 'Web', // Default topic
          'image_url': metadata.imageUrl,
          'author': metadata.author,
          'published_at': (metadata.publishedDate ?? DateTime.now()).toIso8601String(),
        })
        .select()
        .single();
    
    _logger.success('Article added from URL', category: 'Database');
    return response['id'] as String;
  } catch (e, stackTrace) {
    _logger.error('Failed to add article from URL', 
      category: 'Database', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
```

#### 1.4 Add HTML Dependency

**File**: `pubspec.yaml`

```yaml
dependencies:
  html: ^0.15.4  # For HTML parsing
```

### Phase 2: Advanced Content Extraction (Future)

For extracting full article content (not just metadata), use one of these approaches:

#### Option A: Supabase Edge Function (Recommended)

Create `supabase/functions/parse-article/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { extract } from "https://esm.sh/@extractus/article-extractor@7.2.6";

serve(async (req) => {
  try {
    const { url } = await req.json();
    
    // Extract article content
    const article = await extract(url);
    
    if (!article) {
      return new Response(
        JSON.stringify({ error: "Failed to extract article" }),
        { status: 400 }
      );
    }
    
    return new Response(
      JSON.stringify({
        title: article.title,
        content: article.content,
        description: article.description,
        image: article.image,
        author: article.author,
        published: article.published,
        source: article.source,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
});
```

Deploy:
```bash
supabase functions deploy parse-article
```

Call from Flutter:
```dart
final response = await supabase.functions.invoke('parse-article', body: {
  'url': articleUrl,
});
```

#### Option B: Third-Party APIs

**Mercury Parser API** (Open Source):
```dart
Future<Map<String, dynamic>> parseWithMercury(String url) async {
  final response = await http.get(
    Uri.parse('https://mercury.postlight.com/parser?url=$url'),
    headers: {
      'x-api-key': 'YOUR_MERCURY_API_KEY',
    },
  );
  return jsonDecode(response.body);
}
```

**Diffbot API** (Commercial):
```dart
Future<Map<String, dynamic>> parseWithDiffbot(String url) async {
  final response = await http.get(
    Uri.parse('https://api.diffbot.com/v3/article?url=$url&token=YOUR_TOKEN'),
  );
  return jsonDecode(response.body);
}
```

### Phase 3: Website Monitoring (Advanced)

For periodic scraping of websites without RSS:

1. **Store monitoring config** in database:
```sql
CREATE TABLE monitored_websites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  url TEXT NOT NULL,
  css_selector TEXT, -- For extracting article links
  check_interval_hours INTEGER DEFAULT 24,
  last_checked TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);
```

2. **Create background worker** (Supabase Edge Function):
   - Runs on schedule (cron job)
   - Fetches monitored URLs
   - Extracts new article links
   - Parses and stores articles

3. **Notify user** of new articles via push notifications

## Testing Strategy

1. **Test with common news sites**:
   - TechCrunch, Wired, The Verge, Medium
   - Ensure metadata extraction works

2. **Test edge cases**:
   - URLs without Open Graph tags
   - Paywalled articles
   - JavaScript-heavy sites
   - Non-English content

3. **Error handling**:
   - Invalid URLs
   - Network timeouts
   - 404 errors
   - Server errors

## Limitations & Considerations

### Legal Considerations
- **Copyright**: Scraping full article content may violate copyright
- **Terms of Service**: Some sites prohibit scraping
- **Robots.txt**: Respect site crawling rules

### Technical Limitations
- **JavaScript-rendered content**: Requires headless browser (complex)
- **Paywalls**: Can't access premium content
- **Rate limiting**: Sites may block excessive requests
- **Anti-scraping measures**: CAPTCHAs, IP bans

### Recommendations
1. **Start with metadata only** (Open Graph tags)
2. **Use RSS when available** (legal and reliable)
3. **Consider third-party APIs** for content extraction
4. **Add user warnings** about scraping limitations

## Implementation Priority

**Priority 1 (Now)**:
- ✅ URL metadata extraction
- ✅ Add article by URL UI
- ✅ Basic error handling

**Priority 2 (Next Sprint)**:
- [ ] Supabase Edge Function for content extraction
- [ ] Article content preview
- [ ] Better source detection

**Priority 3 (Future)**:
- [ ] Website monitoring
- [ ] PDF/document parsing
- [ ] Social media integration
- [ ] Browser extension for one-click save

## Current Status

✅ URL Parser Service designed
✅ UI mockup created
⏳ Implementation pending user approval
⏳ Testing phase not started

## Next Steps

1. Review this implementation plan
2. Add `html` package to pubspec.yaml
3. Implement `UrlParserService`
4. Add UI for "Add Article by URL"
5. Test with 10-15 different news sites
6. Iterate based on results
7. Consider Edge Function for Phase 2

