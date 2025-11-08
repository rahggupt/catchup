import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/models/source_model.dart';
import '../../../../shared/services/rss_feed_service.dart';
import '../../../../shared/services/article_cache_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// Services
final rssFeedServiceProvider = Provider((ref) => RssFeedService());
final articleCacheServiceProvider = Provider((ref) => ArticleCacheService());

// Feed articles provider with RSS and caching
final feedArticlesProvider = StateNotifierProvider<RssFeedNotifier, AsyncValue<List<ArticleModel>>>((ref) {
  return RssFeedNotifier(
    ref.read(rssFeedServiceProvider),
    ref.read(articleCacheServiceProvider),
    ref.watch(userSourcesProvider),
  );
});

class RssFeedNotifier extends StateNotifier<AsyncValue<List<ArticleModel>>> {
  final RssFeedService _rssService;
  final ArticleCacheService _cacheService;
  final AsyncValue<List<SourceModel>> _sourcesAsync;
  
  bool _isRefreshing = false;
  
  RssFeedNotifier(
    this._rssService,
    this._cacheService,
    this._sourcesAsync,
  ) : super(const AsyncValue.loading()) {
    _loadArticles();
  }

  /// Load articles with caching strategy
  Future<void> _loadArticles() async {
    state = const AsyncValue.loading();
    
    try {
      // Step 1: Check cache first (for instant load)
      final isCacheFresh = await _cacheService.isCacheFresh();
      final cachedArticles = await _cacheService.getCachedArticles();
      
      if (isCacheFresh && cachedArticles != null && cachedArticles.isNotEmpty) {
        // Cache is fresh, use it immediately
        print('Using fresh cache (${cachedArticles.length} articles)');
        state = AsyncValue.data(cachedArticles);
        return;
      }
      
      // Step 2: Show cached data while fetching (if available)
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        final cacheAge = await _cacheService.getCacheAgeMinutes();
        print('Showing cached data (${cacheAge ?? 0} minutes old) while fetching fresh...');
        state = AsyncValue.data(cachedArticles);
      }
      
      // Step 3: Fetch fresh data from RSS
      await _fetchFreshArticles();
      
    } catch (e, stack) {
      print('Error loading articles: $e');
      
      // Try to show cached data on error
      final cachedArticles = await _cacheService.getCachedArticles();
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        print('Error occurred, using cached data');
        state = AsyncValue.data(cachedArticles);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Fetch fresh articles from RSS feeds
  Future<void> _fetchFreshArticles() async {
    await _sourcesAsync.when(
      data: (sources) async {
        // Get only active sources
        final activeSources = sources.where((s) => s.active).toList();
        
        if (activeSources.isEmpty) {
          print('No active sources, showing empty state');
          state = const AsyncValue.data([]);
          return;
        }
        
        final sourceNames = activeSources.map((s) => s.name).toList();
        print('Fetching from ${sourceNames.length} active sources: $sourceNames');
        
        // Progressive loading: Fetch each source individually and update UI
        final List<ArticleModel> allArticles = [];
        
        for (final sourceName in sourceNames) {
          try {
            print('Fetching from $sourceName...');
            final articles = await _rssService.fetchFromSource(sourceName);
            
            if (articles.isNotEmpty) {
              allArticles.addAll(articles);
              
              // Sort by date (newest first)
              allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
              
              // Progressive update: Show articles as they come in
              state = AsyncValue.data(List.from(allArticles));
              print('✓ Added ${articles.length} articles from $sourceName (total: ${allArticles.length})');
            }
          } catch (e) {
            print('✗ Failed to fetch from $sourceName: $e');
            // Continue with other sources
          }
        }
        
        // Final update
        if (allArticles.isNotEmpty) {
          print('✓ Fetch complete! Total articles: ${allArticles.length}');
          state = AsyncValue.data(allArticles);
          
          // Cache the results
          await _cacheService.cacheArticles(allArticles);
        } else {
          print('No articles fetched from any source');
          state = const AsyncValue.data([]);
        }
      },
      loading: () {
        print('Sources still loading...');
      },
      error: (e, stack) {
        print('Error with sources: $e');
        state = AsyncValue.error(e, stack);
      },
    );
  }

  /// Refresh articles (pull to refresh)
  Future<void> refresh() async {
    if (_isRefreshing) {
      print('Already refreshing, skipping...');
      return;
    }
    
    _isRefreshing = true;
    print('Manual refresh triggered');
    
    try {
      await _fetchFreshArticles();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Force refresh (ignore cache)
  Future<void> forceRefresh() async {
    print('Force refresh: clearing cache');
    await _cacheService.clearCache();
    await _loadArticles();
  }

  /// Remove article from list
  void removeArticle(String articleId) {
    state.whenData((articles) {
      final updatedArticles = articles.where((a) => a.id != articleId).toList();
      state = AsyncValue.data(updatedArticles);
    });
  }
}

// Client-side time filter
final selectedTimeFilterProvider = StateProvider<String>((ref) => 'All');

// Filtered articles based on time
final filteredArticlesProvider = Provider<AsyncValue<List<ArticleModel>>>((ref) {
  final articlesAsync = ref.watch(feedArticlesProvider);
  final timeFilter = ref.watch(selectedTimeFilterProvider);
  
  return articlesAsync.when(
    data: (articles) {
      if (timeFilter == 'All') {
        return AsyncValue.data(articles);
      }
      
      // Calculate cutoff time
      final now = DateTime.now();
      DateTime cutoff;
      
      switch (timeFilter) {
        case '2h':
          cutoff = now.subtract(const Duration(hours: 2));
          break;
        case '6h':
          cutoff = now.subtract(const Duration(hours: 6));
          break;
        case '24h':
          cutoff = now.subtract(const Duration(hours: 24));
          break;
        default:
          cutoff = DateTime(2000); // Show all
      }
      
      // Filter articles
      final filtered = articles.where((article) {
        return article.publishedAt.isAfter(cutoff);
      }).toList();
      
      print('Time filter $timeFilter: ${filtered.length} of ${articles.length} articles');
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

// Topic filter provider
final selectedFilterProvider = StateProvider<String>((ref) => 'All Sources');

// Available filters
final filtersProvider = Provider<List<String>>((ref) {
  return ['All Sources', 'AI Topics', 'Friends\' Adds', 'Tech', 'Science'];
});

// Current article index provider
final currentArticleIndexProvider = StateProvider<int>((ref) => 0);

// Liked articles provider
final likedArticlesProvider = StateNotifierProvider<LikedArticlesNotifier, Set<String>>((ref) {
  return LikedArticlesNotifier();
});

class LikedArticlesNotifier extends StateNotifier<Set<String>> {
  LikedArticlesNotifier() : super({});

  void toggleLike(String articleId) {
    final newState = Set<String>.from(state);
    if (newState.contains(articleId)) {
      newState.remove(articleId);
    } else {
      newState.add(articleId);
    }
    state = newState;
  }

  bool isLiked(String articleId) {
    return state.contains(articleId);
  }
}

