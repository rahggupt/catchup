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
  bool _isLoadingMore = false;
  
  // Pagination state
  List<ArticleModel> _allFetchedArticles = [];
  int _currentPage = 0;
  static const int _pageSize = 10;
  
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
    _logger.info('🔄 START _loadArticles - Setting state to loading', category: 'Feed');
    state = const AsyncValue.loading();
    
    try {
      _logger.info('📦 Step 1: Checking cache...', category: 'Feed');
      
      // Step 1: Check cache first (for instant load)
      final isCacheFresh = await _cacheService.isCacheFresh();
      _logger.info('📦 Cache fresh? $isCacheFresh', category: 'Feed');
      
      final cachedArticles = await _cacheService.getCachedArticles();
      _logger.info('📦 Cached articles count: ${cachedArticles?.length ?? 0}', category: 'Feed');
      
      if (isCacheFresh && cachedArticles != null && cachedArticles.isNotEmpty) {
        // Cache is fresh, use it immediately with pagination
        _logger.success('✅ Using fresh cache (${cachedArticles.length} articles)', category: 'Feed');
        _allFetchedArticles = cachedArticles;
        _currentPage = 0;
        
        // Show first page from cache (pagination enabled)
        final firstPage = cachedArticles.take(_pageSize).toList();
        _logger.info('📄 Showing first ${firstPage.length} of ${cachedArticles.length} cached articles (pagination ON)', category: 'Feed');
        _logger.info('🔄 Setting state with ${firstPage.length} articles...', category: 'Feed');
        state = AsyncValue.data(firstPage);
        _logger.success('✅ State updated! state.value.length = ${state.value?.length}', category: 'Feed');
        return;
      }
      
      _logger.info('📦 Step 2: Cache not fresh or empty, checking if we can show stale cache...', category: 'Feed');
      
      // Step 2: Show cached data while fetching (if available)
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        final cacheAge = await _cacheService.getCacheAgeMinutes();
        _logger.warning('⏰ Showing stale cache (${cacheAge ?? 0} minutes old, ${cachedArticles.length} articles)', category: 'Feed');
        _allFetchedArticles = cachedArticles;
        _currentPage = 0;
        
        // Show first page from stale cache (pagination enabled)
        final firstPage = cachedArticles.take(_pageSize).toList();
        _logger.info('📄 Showing first ${firstPage.length} of ${cachedArticles.length} stale cached articles (pagination ON)', category: 'Feed');
        _logger.info('🔄 Setting state with ${firstPage.length} articles...', category: 'Feed');
        state = AsyncValue.data(firstPage);
        _logger.info('📊 State updated with stale cache (showing ${state.value?.length}), now fetching fresh...', category: 'Feed');
      } else {
        _logger.warning('⚠️ No cache available, will fetch fresh data', category: 'Feed');
      }
      
      // Step 3: Fetch fresh data from RSS
      _logger.info('🌐 Step 3: Fetching fresh articles from RSS...', category: 'Feed');
      await _fetchFreshArticles();
      
    } catch (e, stack) {
      _logger.error('❌ ERROR in _loadArticles', category: 'Feed', error: e, stackTrace: stack);
      
      // Try to show cached data on error
      _logger.info('🔄 Attempting to fallback to cache after error...', category: 'Feed');
      final cachedArticles = await _cacheService.getCachedArticles();
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        _logger.warning('⚠️ Error occurred, using cached data (${cachedArticles.length} articles)', category: 'Feed');
        _allFetchedArticles = cachedArticles;
        _currentPage = 0;
        
        // Show first page from error fallback cache (pagination enabled)
        final firstPage = cachedArticles.take(_pageSize).toList();
        _logger.info('📄 Showing first ${firstPage.length} of ${cachedArticles.length} error fallback articles (pagination ON)', category: 'Feed');
        _logger.info('🔄 Setting state with ${firstPage.length} articles...', category: 'Feed');
        state = AsyncValue.data(firstPage);
        _logger.success('✅ State updated from error fallback! state.value.length = ${state.value?.length}', category: 'Feed');
      } else {
        _logger.error('❌ No cache available for error fallback, showing error state', category: 'Feed');
        state = AsyncValue.error(e, stack);
      }
    }
    _logger.info('🏁 END _loadArticles', category: 'Feed');
  }

  /// Fetch fresh articles from RSS feeds
  Future<void> _fetchFreshArticles() async {
    _logger.info('🌐 START _fetchFreshArticles', category: 'Feed');
    
    final sourcesAsync = _ref.read(userSourcesProvider);
    _logger.info('📚 Got userSourcesProvider state: ${sourcesAsync.runtimeType}', category: 'Feed');
    
    await sourcesAsync.when(
      data: (sources) async {
        _logger.info('📚 Sources data received: ${sources.length} total sources', category: 'Feed');
        
        // Get only active sources
        var activeSources = sources.where((s) => s.active).toList();
        _logger.info('✅ Active sources: ${activeSources.length} (${activeSources.map((s) => s.name).toList()})', category: 'Feed');
        
        // Apply topic filter if selected
        final selectedTopic = _ref.read(selectedTopicFilterProvider);
        _logger.info('🏷️ Selected topic filter: ${selectedTopic ?? "None"}', category: 'Feed');
        
        if (selectedTopic != null) {
          if (selectedTopic == 'friends') {
            // Filter to sources added by friends (not current user)
            // For now, show all sources as we don't track who added them yet
            _logger.info('👥 Friends filter selected (showing all for now)', category: 'Feed');
          } else {
            // Filter by topic
            final beforeFilter = activeSources.length;
            activeSources = activeSources.where((source) {
              final hasTopics = source.topics != null && source.topics!.contains(selectedTopic);
              _logger.info('  - ${source.name}: topics=${source.topics}, has "$selectedTopic"? $hasTopics', category: 'Feed');
              return hasTopics;
            }).toList();
            _logger.info('🔍 After topic filter: ${activeSources.length}/$beforeFilter sources', category: 'Feed');
          }
        }
        
        if (activeSources.isEmpty) {
          _logger.warning('⚠️ NO ACTIVE SOURCES! Showing empty state', category: 'Feed');
          state = const AsyncValue.data([]);
          _logger.info('📊 State set to empty array', category: 'Feed');
          return;
        }
        
        final sourceNames = activeSources.map((s) => s.name).toList();
        final articleCount = activeSources.isNotEmpty 
            ? (activeSources.first.articleCount ?? 5) 
            : 5;
        
        _logger.success('🎯 Will fetch from ${sourceNames.length} sources: $sourceNames (limit: $articleCount per source)', category: 'Feed');
        
        // Fetch articles from all sources
        final List<ArticleModel> allArticles = [];
        
        for (final source in activeSources) {
          try {
            _logger.info('📡 Fetching from ${source.name}...', category: 'Feed');
            _logger.info('  URL: ${source.url}', category: 'Feed');
            _logger.info('  Limit: ${source.articleCount ?? 5}', category: 'Feed');
            
            final articles = await _rssService.fetchFromSource(
              source.name,
              limit: source.articleCount ?? 5,
              customFeedUrl: source.url, // Pass custom URL from database
            );
            
            _logger.info('📥 Received ${articles.length} articles from ${source.name}', category: 'Feed');
            
            if (articles.isNotEmpty) {
              allArticles.addAll(articles);
              _logger.success('✅ Added ${articles.length} articles from ${source.name} (total now: ${allArticles.length})', category: 'Feed');
            } else {
              _logger.warning('⚠️ No articles from ${source.name}', category: 'Feed');
            }
          } catch (e) {
            _logger.error('❌ Failed to fetch from ${source.name}', category: 'Feed', error: e);
            // Continue with other sources
          }
        }
        
        _logger.info('🔄 Sorting ${allArticles.length} articles by date...', category: 'Feed');
        
        // Sort by date (newest first)
        allArticles.sort((a, b) => (b.publishedAt ?? DateTime.now()).compareTo(a.publishedAt ?? DateTime.now()));
        
        // Filter out rejected articles
        final rejectedArticles = _ref.read(rejectedArticlesProvider);
        final beforeFilterCount = allArticles.length;
        final filteredArticles = allArticles.where((article) => !rejectedArticles.contains(article.id)).toList();
        final filteredCount = beforeFilterCount - filteredArticles.length;
        if (filteredCount > 0) {
          _logger.info('🚫 Filtered out $filteredCount rejected articles', category: 'Feed');
        }
        
        _logger.info('💾 Storing ${filteredArticles.length} non-rejected articles in pagination state...', category: 'Feed');
        
        // Store all articles and reset pagination
        _allFetchedArticles = filteredArticles;
        _currentPage = 0;
        
        _logger.info('📊 Pagination state updated: _allFetchedArticles=${_allFetchedArticles.length}, _currentPage=$_currentPage', category: 'Feed');
        
        // Expose only the first page (10 articles) - Pagination enabled
        if (filteredArticles.isNotEmpty) {
          final firstPage = filteredArticles.take(_pageSize).toList();
          _logger.success('🎉 Fetch complete! Total: ${filteredArticles.length}, showing first ${firstPage.length} (pagination ON)', category: 'Feed');
          _logger.info('📄 First 3 article titles:', category: 'Feed');
          for (var i = 0; i < firstPage.length && i < 3; i++) {
            _logger.info('  ${i + 1}. ${firstPage[i].title.substring(0, firstPage[i].title.length.clamp(0, 50))}...', category: 'Feed');
          }
          
          _logger.info('🔄 Setting state with ${firstPage.length} articles...', category: 'Feed');
          state = AsyncValue.data(firstPage);
          _logger.success('✅ State updated! state.value.length = ${state.value?.length}', category: 'Feed');
          
          // Cache all results (including rejected ones for future use)
          _logger.info('💾 Caching ${allArticles.length} articles...', category: 'Feed');
          await _cacheService.cacheArticles(allArticles);
          _logger.success('✅ Articles cached successfully', category: 'Feed');
        } else {
          _logger.warning('⚠️ NO ARTICLES FETCHED from any source - setting empty state', category: 'Feed');
          state = const AsyncValue.data([]);
          _logger.info('📊 State set to empty array', category: 'Feed');
        }
      },
      loading: () {
        _logger.warning('⏳ Sources still loading...', category: 'Feed');
      },
      error: (e, stack) {
        _logger.error('❌ Error with sources provider', category: 'Feed', error: e, stackTrace: stack);
        state = AsyncValue.error(e, stack);
      },
    );
    
    _logger.info('🏁 END _fetchFreshArticles', category: 'Feed');
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

  /// Load more articles (lazy loading pagination)
  Future<void> loadMoreArticles() async {
    if (_isLoadingMore) {
      _logger.info('⏭️ Already loading more articles, skipping...', category: 'Feed');
      return;
    }
    
    _isLoadingMore = true;
    _logger.info('📚 START loadMoreArticles', category: 'Feed');
    
    try {
      // Check if we have more articles to show
      final currentlyShowing = state.value?.length ?? 0;
      final totalAvailable = _allFetchedArticles.length;
      
      _logger.info('📊 Current state: showing=$currentlyShowing, available=$totalAvailable, page=$_currentPage', category: 'Feed');
      
      if (currentlyShowing >= totalAvailable) {
        _logger.info('✋ All articles already shown ($currentlyShowing of $totalAvailable)', category: 'Feed');
        return;
      }
      
      // Get next page of articles
      _currentPage++;
      final endIndex = (_currentPage + 1) * _pageSize;
      final nextBatch = _allFetchedArticles.take(endIndex.clamp(0, totalAvailable)).toList();
      
      _logger.success('✅ Loading page ${_currentPage + 1}: now showing ${nextBatch.length} of $totalAvailable', category: 'Feed');
      state = AsyncValue.data(nextBatch);
      _logger.info('📊 State updated with ${nextBatch.length} articles', category: 'Feed');
    } finally {
      _isLoadingMore = false;
      _logger.info('🏁 END loadMoreArticles', category: 'Feed');
    }
  }
  
  /// Check if more articles are available
  bool get hasMoreArticles {
    final currentlyShowing = state.value?.length ?? 0;
    return currentlyShowing < _allFetchedArticles.length;
  }
  
  /// Check if currently loading more
  bool get isLoadingMore => _isLoadingMore;

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

