import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/rss_feed_provider.dart';
import '../widgets/swipeable_article_card.dart';
import '../widgets/article_progress_indicator.dart';
import '../widgets/add_source_modal.dart';
import '../../../collections/presentation/widgets/add_to_collection_modal.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Articles'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, topic, or source...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            // TODO: Implement search functionality
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Searching for: $query')),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedArticlesAsync = ref.watch(filteredArticlesProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final filters = ref.watch(filtersProvider);
    final selectedTime = ref.watch(selectedTimeFilterProvider);

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
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _showSearchDialog(context);
                            },
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
                              final selectedTime = watchRef.watch(selectedTimeFilterProvider);
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
                                      ref.read(feedArticlesProvider.notifier).refresh();
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
                  const SizedBox(height: 12),
                  
                  // Topic Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isSelected = filter == selectedFilter;
                        return FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(selectedFilterProvider.notifier).state =
                                filter;
                          },
                          backgroundColor:
                              isSelected ? AppTheme.primaryBlue : AppTheme.backgroundLight,
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textGray,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Article Card Stack
            Expanded(
              child: feedArticlesAsync.when(
                data: (articles) {
                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No articles yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add sources to start seeing articles',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  final currentIndex = ref.watch(currentArticleIndexProvider);
                  
                  if (currentIndex >= articles.length) {
                    // All articles viewed
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You\'re all caught up!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new articles',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(currentArticleIndexProvider.notifier).state = 0;
                              ref.read(feedArticlesProvider.notifier).refresh();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Feed'),
                          ),
                        ],
                      ),
                    );
                  }

                  final currentArticle = articles[currentIndex];

                  return Stack(
                    children: [
                      // Current article card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SwipeableArticleCard(
                          article: currentArticle,
                          onSwipeLeft: () {
                            // Dismiss
                            ref.read(currentArticleIndexProvider.notifier).state++;
                          },
                          onSwipeRight: () {
                            // Add to collection
                            _showSaveToCollectionModal(context, currentArticle);
                            ref.read(currentArticleIndexProvider.notifier).state++;
                          },
                        ),
                      ),
                      // Progress Indicator
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: ArticleProgressIndicator(
                          totalCount: articles.length,
                          currentIndex: currentIndex,
                        ),
                      ),
                      // Refresh hint
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(feedArticlesProvider.notifier).refresh();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 100),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to refresh',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      Text(
                        'Failed to load articles',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(feedArticlesProvider.notifier).refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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

  void _showSaveToCollectionModal(BuildContext context, article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCollectionModal(article: article),
    );
  }
}

