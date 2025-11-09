import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/rss_feed_provider.dart';
import '../widgets/scrollable_article_card.dart';
import '../widgets/add_source_modal.dart';
import '../../../collections/presentation/widgets/add_to_collection_modal.dart';
import '../../../../shared/models/article_model.dart';

class ScrollableFeedScreen extends ConsumerStatefulWidget {
  const ScrollableFeedScreen({super.key});

  @override
  ConsumerState<ScrollableFeedScreen> createState() => _ScrollableFeedScreenState();
}

class _ScrollableFeedScreenState extends ConsumerState<ScrollableFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Articles'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title, topic, or source...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<ArticleModel> _filterArticles(List<ArticleModel> articles) {
    if (_searchQuery.isEmpty) return articles;
    
    return articles.where((article) {
      return article.title.toLowerCase().contains(_searchQuery) ||
             article.summary.toLowerCase().contains(_searchQuery) ||
             article.source.toLowerCase().contains(_searchQuery) ||
             article.topic.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _showSaveToCollectionModal(BuildContext context, ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCollectionModal(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedArticlesAsync = ref.watch(filteredArticlesProvider);
    final selectedTime = ref.watch(selectedTimeFilterProvider);
    final likedArticles = ref.watch(likedArticlesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              ref.read(feedArticlesProvider.notifier).refresh();
                            },
                            tooltip: 'Refresh',
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _showSearchDialog(context);
                            },
                            tooltip: 'Search',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddSourceModal(),
                              );
                            },
                            tooltip: 'Add Source',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Time Filter Row
                  Row(
                    children: [
                      const Text(
                        'Time: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: Consumer(
                            builder: (context, watchRef, _) {
                              final timeFilters = ['2h', '6h', '24h', 'All'];
                              
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: timeFilters.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final filter = timeFilters[index];
                                  final isSelected = filter == selectedTime;
                                  return FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref.read(selectedTimeFilterProvider.notifier).state = filter;
                                    },
                                    backgroundColor: isSelected 
                                        ? AppTheme.secondaryPurple 
                                        : AppTheme.backgroundLight,
                                    selectedColor: AppTheme.secondaryPurple,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textGray,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Articles List
            Expanded(
              child: feedArticlesAsync.when(
                data: (articles) {
                  final filteredArticles = _filterArticles(articles);
                  
                  if (filteredArticles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.rss_feed,
                            size: 64,
                            color: AppTheme.textGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No articles match your search'
                                : selectedTime != 'All'
                                    ? 'No articles in last $selectedTime'
                                    : 'No articles available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            TextButton.icon(
                              onPressed: () {
                                ref.read(feedArticlesProvider.notifier).refresh();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Feed'),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(feedArticlesProvider.notifier).refresh();
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredArticles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredArticles.length) {
                          // End of list indicator
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 48,
                                  color: AppTheme.successGreen.withOpacity(0.7),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'re all caught up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textGray.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${filteredArticles.length} articles read',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textGray.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final article = filteredArticles[index];
                        final isLiked = likedArticles.contains(article.id);

                        return ScrollableArticleCard(
                          article: article,
                          isLiked: isLiked,
                          onBookmark: () {
                            _showSaveToCollectionModal(context, article);
                          },
                          onLike: () {
                            ref.read(likedArticlesProvider.notifier).toggleLike(article.id);
                          },
                          onShare: () {
                            Share.share(
                              '${article.title}\n\nRead more: ${article.url}',
                              subject: article.title,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Fetching articles from RSS feeds...',
                        style: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load articles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your internet connection',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(feedArticlesProvider.notifier).refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

