import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/models/source_model.dart';
import '../../../../shared/services/rss_feed_service.dart';
import '../../../../shared/services/article_cache_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// Services
final rssFeedServiceProvider = Provider((ref) => RssFeedService());
final articleCacheServiceProvider = Provider((ref) => ArticleCacheService());

// Feed articles provider with RSS and caching
final feedArticlesProvider = StateNotifierProvider<RssFeedNotifier, AsyncValue<List<ArticleModel>>>((ref) {
  return RssFeedNotifier(
    ref.read(rssFeedServiceProvider),
    ref.read(articleCacheServiceProvider),
    ref,
  );
});

class RssFeedNotifier extends StateNotifier<AsyncValue<List<ArticleModel>>> {
  final RssFeedService _rssService;
  final ArticleCacheService _cacheService;
  final Ref _ref;
  final LoggerService _logger = LoggerService();
  
  bool _isRefreshing = false;
  
  RssFeedNotifier(
    this._rssService,
    this._cacheService,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    // Watch sources and reload whenever they change
    _ref.listen<AsyncValue<List<SourceModel>>>(
      userSourcesProvider,
      (previous, next) {
        next.whenData((sources) {
          _logger.info('Sources changed! Active sources: ${sources.where((s) => s.active).map((s) => s.name).toList()}', category: 'Feed');
          // Clear cache and reload immediately
          _cacheService.clearCache().then((_) => _loadArticles());
        });
      },
      fireImmediately: true,
    );
    
    // Watch topic filter and reload when it changes
    _ref.listen<String?>(
      selectedTopicFilterProvider,
      (previous, next) {
        if (previous != next) {
          _logger.info('Topic filter changed! New topic: ${next ?? "All Sources"}', category: 'Feed');
          // Clear cache and reload immediately
          _cacheService.clearCache().then((_) => _loadArticles());
        }
      },
    );
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
        _logger.info('Using fresh cache (${cachedArticles.length} articles)', category: 'Feed');
        state = AsyncValue.data(cachedArticles);
        return;
      }
      
      // Step 2: Show cached data while fetching (if available)
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        final cacheAge = await _cacheService.getCacheAgeMinutes();
        _logger.info('Showing cached data (${cacheAge ?? 0} minutes old) while fetching fresh', category: 'Feed');
        state = AsyncValue.data(cachedArticles);
      }
      
      // Step 3: Fetch fresh data from RSS
      await _fetchFreshArticles();
      
    } catch (e, stack) {
      _logger.error('Error loading articles', category: 'Feed', error: e, stackTrace: stack);
      
      // Try to show cached data on error
      final cachedArticles = await _cacheService.getCachedArticles();
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        _logger.warning('Error occurred, using cached data', category: 'Feed');
        state = AsyncValue.data(cachedArticles);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Fetch fresh articles from RSS feeds
  Future<void> _fetchFreshArticles() async {
    final sourcesAsync = _ref.read(userSourcesProvider);
    await sourcesAsync.when(
      data: (sources) async {
        // Get only active sources
        var activeSources = sources.where((s) => s.active).toList();
        
        // Apply topic filter if selected
        final selectedTopic = _ref.read(selectedTopicFilterProvider);
        if (selectedTopic != null) {
          if (selectedTopic == 'friends') {
            // Filter to sources added by friends (not current user)
            // For now, show all sources as we don't track who added them yet
            _logger.info('Friends filter selected (showing all for now)', category: 'Feed');
          } else {
            // Filter by topic
            activeSources = activeSources.where((source) {
              return source.topics != null && source.topics!.contains(selectedTopic);
            }).toList();
            _logger.info('Filtered to ${activeSources.length} sources with topic: $selectedTopic', category: 'Feed');
          }
        }
        
        if (activeSources.isEmpty) {
          _logger.warning('No active sources matching filter, showing empty state', category: 'Feed');
          state = const AsyncValue.data([]);
          return;
        }
        
        final sourceNames = activeSources.map((s) => s.name).toList();
        final articleCount = activeSources.isNotEmpty 
            ? (activeSources.first.articleCount ?? 5) 
            : 5;
        
        _logger.info('Fetching from ${sourceNames.length} active sources: $sourceNames (limit: $articleCount per source)', category: 'Feed');
        
        // Progressive loading: Fetch each source individually and update UI
        final List<ArticleModel> allArticles = [];
        
        for (final source in activeSources) {
          try {
            _logger.info('Fetching from ${source.name}...', category: 'Feed');
            final articles = await _rssService.fetchFromSource(
              source.name,
              limit: source.articleCount ?? 5,
            );
            
            if (articles.isNotEmpty) {
              allArticles.addAll(articles);
              
              // Sort by date (newest first)
              allArticles.sort((a, b) => (b.publishedAt ?? DateTime.now()).compareTo(a.publishedAt ?? DateTime.now()));
              
              // Progressive update: Show articles as they come in
              state = AsyncValue.data(List.from(allArticles));
              _logger.success('Added ${articles.length} articles from ${source.name} (total: ${allArticles.length})', category: 'Feed');
            }
          } catch (e) {
            _logger.error('Failed to fetch from ${source.name}', category: 'Feed', error: e);
            // Continue with other sources
          }
        }
        
        // Final update
        if (allArticles.isNotEmpty) {
          _logger.success('Fetch complete! Total articles: ${allArticles.length}', category: 'Feed');
          state = AsyncValue.data(allArticles);
          
          // Cache the results
          await _cacheService.cacheArticles(allArticles);
        } else {
          _logger.warning('No articles fetched from any source', category: 'Feed');
          state = const AsyncValue.data([]);
        }
      },
      loading: () {
        _logger.info('Sources still loading...', category: 'Feed');
      },
      error: (e, stack) {
        _logger.error('Error with sources', category: 'Feed', error: e, stackTrace: stack);
        state = AsyncValue.error(e, stack);
      },
    );
  }

  /// Refresh articles (pull to refresh)
  Future<void> refresh() async {
    if (_isRefreshing) {
      _logger.info('Already refreshing, skipping...', category: 'Feed');
      return;
    }
    
    _isRefreshing = true;
    _logger.info('Manual refresh triggered', category: 'Feed');
    
    try {
      await _fetchFreshArticles();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Force refresh (ignore cache)
  Future<void> forceRefresh() async {
    _logger.info('Force refresh: clearing cache', category: 'Feed');
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

// Topic filter provider
final selectedTopicFilterProvider = StateProvider<String?>((ref) => null);

// Filtered articles based on time and rejected status
final filteredArticlesProvider = Provider<AsyncValue<List<ArticleModel>>>((ref) {
  final logger = LoggerService();
  final articlesAsync = ref.watch(feedArticlesProvider);
  final timeFilter = ref.watch(selectedTimeFilterProvider);
  final rejectedArticles = ref.watch(rejectedArticlesProvider);
  
  return articlesAsync.when(
    data: (articles) {
      logger.info('FILTERING: TimeFilter=$timeFilter, Total=${articles.length}, Rejected=${rejectedArticles.length}', category: 'Feed');
      
      // First, filter out rejected articles
      var filtered = articles.where((article) => !rejectedArticles.contains(article.id)).toList();
      final rejectedCount = articles.length - filtered.length;
      if (rejectedCount > 0) {
        logger.info('Filtered out $rejectedCount rejected articles', category: 'Feed');
      }
      
      if (timeFilter == 'All') {
        logger.info('Showing all non-rejected articles (no time filter)', category: 'Feed');
        return AsyncValue.data(filtered);
      }
      
      // Calculate cutoff time
      final now = DateTime.now();
      DateTime cutoff;
      
      switch (timeFilter) {
        case '2h':
          cutoff = now.subtract(const Duration(hours: 2));
          logger.info('Cutoff time (2h): $cutoff', category: 'Feed');
          break;
        case '6h':
          cutoff = now.subtract(const Duration(hours: 6));
          logger.info('Cutoff time (6h): $cutoff', category: 'Feed');
          break;
        case '24h':
          cutoff = now.subtract(const Duration(hours: 24));
          logger.info('Cutoff time (24h): $cutoff', category: 'Feed');
          break;
        default:
          cutoff = DateTime(2000); // Show all
          logger.info('Showing all (default)', category: 'Feed');
      }
      
      // Filter articles by time
      filtered = filtered.where((article) {
        final pubDate = article.publishedAt ?? DateTime.now();
        final passes = pubDate.isAfter(cutoff);
        return passes;
      }).toList();
      
      logger.success('Final filtered result: ${filtered.length} of ${articles.length} articles', category: 'Feed');
      
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

// Rejected articles provider with persistence
final rejectedArticlesProvider = StateNotifierProvider<RejectedArticlesNotifier, Set<String>>((ref) {
  return RejectedArticlesNotifier();
});

class RejectedArticlesNotifier extends StateNotifier<Set<String>> {
  final LoggerService _logger = LoggerService();
  static const String _storageKey = 'rejected_articles';

  RejectedArticlesNotifier() : super({}) {
    _loadRejectedArticles();
  }

  Future<void> _loadRejectedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rejectedList = prefs.getStringList(_storageKey) ?? [];
      state = rejectedList.toSet();
      _logger.info('Loaded ${state.length} rejected articles from storage', category: 'Feed');
    } catch (e, stackTrace) {
      _logger.error('Failed to load rejected articles', category: 'Feed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _saveRejectedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, state.toList());
      _logger.info('Saved ${state.length} rejected articles to storage', category: 'Feed');
    } catch (e, stackTrace) {
      _logger.error('Failed to save rejected articles', category: 'Feed', error: e, stackTrace: stackTrace);
    }
  }

  void rejectArticle(String articleId) {
    _logger.info('Marking article as rejected: $articleId', category: 'Feed');
    final newState = Set<String>.from(state);
    newState.add(articleId);
    state = newState;
    _saveRejectedArticles();
  }

  bool isRejected(String articleId) {
    return state.contains(articleId);
  }

  Future<void> clearRejectedArticles() async {
    _logger.info('Clearing all rejected articles', category: 'Feed');
    state = {};
    _saveRejectedArticles();
  }
}

