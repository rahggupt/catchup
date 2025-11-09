import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/rss_feed_provider.dart';
import '../widgets/scrollable_article_card.dart';
import '../widgets/add_source_modal.dart';
import '../../../collections/presentation/widgets/add_to_collection_modal.dart';
import '../../../../shared/models/article_model.dart';

class SwipeFeedScreen extends ConsumerStatefulWidget {
  const SwipeFeedScreen({super.key});

  @override
  ConsumerState<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends ConsumerState<SwipeFeedScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  
  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _showSaveToCollectionModal(BuildContext context, ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddToCollectionModal(article: article),
      ),
    );
  }

  Future<void> _shareArticle(ArticleModel article) async {
    try {
      final shareText = '''
${article.title}

${article.summary}

Read more: ${article.url}

Shared via CatchUp
''';
      
      await Share.share(
        shareText,
        subject: article.title,
      );
      
      print('✓ Article shared: ${article.title}');
    } catch (e) {
      print('✗ Error sharing article: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedArticlesAsync = ref.watch(filteredArticlesProvider);
    final selectedTime = ref.watch(selectedTimeFilterProvider);
    final likedArticles = ref.watch(likedArticlesProvider);
    final currentIndex = ref.watch(currentArticleIndexProvider);

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
                              ref.read(currentArticleIndexProvider.notifier).state = 0;
                            },
                            tooltip: 'Refresh',
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
                                      ref.read(currentArticleIndexProvider.notifier).state = 0;
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
            
            // Article Swiper
            Expanded(
              child: feedArticlesAsync.when(
                data: (articles) {
                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rss_feed,
                            size: 64,
                            color: AppTheme.textGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedTime != 'All' 
                                ? 'No articles in last $selectedTime'
                                : 'No articles available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                          const Text(
                            'You\'re all caught up!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${articles.length} articles read',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGray,
                            ),
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

                  // Show current article with swipe
                  return Stack(
                    children: [
                      // Swipeable Card with visual indicators
                      CardSwiper(
                        controller: _swiperController,
                        cardsCount: articles.length - currentIndex,
                        numberOfCardsDisplayed: 1,
                        backCardOffset: const Offset(0, 0),
                        padding: const EdgeInsets.all(16),
                        duration: const Duration(milliseconds: 250),
                        maxAngle: 25,
                        threshold: 80,
                        scale: 0.95,
                        isLoop: false,
                        allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                          horizontal: true,
                          vertical: false,
                        ),
                        onSwipe: (previousIndex, currentIndex2, direction) {
                          final article = articles[currentIndex + previousIndex];
                          
                          if (direction == CardSwiperDirection.right) {
                            // Swipe RIGHT = SAVE to collection
                            print('✓ Swiped RIGHT - Saving article: ${article.title}');
                            // Add haptic feedback
                            HapticFeedback.mediumImpact();
                            // Show modal after a brief delay for better UX
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (context.mounted) {
                                _showSaveToCollectionModal(context, article);
                              }
                            });
                          } else if (direction == CardSwiperDirection.left) {
                            // Swipe LEFT = DISMISS/SKIP
                            print('✗ Swiped LEFT - Skipping article: ${article.title}');
                            // Add haptic feedback
                            HapticFeedback.lightImpact();
                          }
                          
                          // Move to next article
                          final nextIndex = currentIndex + previousIndex + 1;
                          ref.read(currentArticleIndexProvider.notifier).state = nextIndex;
                          return true;
                        },
                        onEnd: () {
                          // All articles swiped
                          ref.read(currentArticleIndexProvider.notifier).state = articles.length;
                        },
                        cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                          final article = articles[currentIndex + index];
                          final isLiked = likedArticles.contains(article.id);
                          
                          return Stack(
                            children: [
                              // Article Card
                              ScrollableArticleCard(
                                article: article,
                                isLiked: isLiked,
                                onBookmark: () {
                                  _showSaveToCollectionModal(context, article);
                                },
                                onLike: () {
                                  ref.read(likedArticlesProvider.notifier).toggleLike(article.id);
                                },
                                onShare: () {
                                  _shareArticle(article);
                                },
                              ),
                              
                              // Swipe indicators with enhanced visibility
                              if (horizontalOffsetPercentage > 0) ...[
                                // Swiping RIGHT - Show SAVE indicator
                                Positioned(
                                  top: 80,
                                  left: 30,
                                  child: Opacity(
                                    opacity: (horizontalOffsetPercentage * 1.5).clamp(0.0, 1.0).toDouble(),
                                    child: Transform.scale(
                                      scale: 0.7 + (horizontalOffsetPercentage * 0.8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.successGreen.withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bookmark_add, color: Colors.white, size: 28),
                                            SizedBox(width: 12),
                                            Text(
                                              'SAVE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (horizontalOffsetPercentage < 0) ...[
                                // Swiping LEFT - Show SKIP indicator
                                Positioned(
                                  top: 80,
                                  right: 30,
                                  child: Opacity(
                                    opacity: ((-horizontalOffsetPercentage) * 1.5).clamp(0.0, 1.0).toDouble(),
                                    child: Transform.scale(
                                      scale: 0.7 + ((-horizontalOffsetPercentage) * 0.8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorRed,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.errorRed.withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.close_rounded, color: Colors.white, size: 28),
                                            SizedBox(width: 12),
                                            Text(
                                              'SKIP',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      
                      // Progress Indicator at Bottom
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:                           Text(
                            '${currentIndex + 1}/${articles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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

