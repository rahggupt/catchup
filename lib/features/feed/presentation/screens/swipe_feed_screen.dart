import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../../shared/utils/error_message_formatter.dart';
import '../providers/rss_feed_provider.dart';
import '../widgets/article_card.dart';
import '../widgets/add_source_modal.dart';
import '../../../collections/presentation/widgets/add_to_collection_modal.dart';
import '../../../ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../../../shared/models/article_model.dart';

class SwipeFeedScreen extends ConsumerStatefulWidget {
  const SwipeFeedScreen({super.key});

  @override
  ConsumerState<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends ConsumerState<SwipeFeedScreen> {
  final LoggerService _logger = LoggerService();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  
  // Track card animations for each article
  final Map<String, AnimationController> _cardAnimations = {};
  
  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _cardAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _showSaveToCollectionModal(BuildContext context, ArticleModel article) async {
    _logger.info('Opening save to collection modal for: ${article.title}', category: 'Feed');
    await showModalBottomSheet(
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

  void _openAskAIWithArticle(BuildContext context, ArticleModel article) {
    // Navigate to AI Chat screen with article context
    // The AI will automatically generate a summary
    _logger.info('Opening Ask AI for article: ${article.title}', category: 'Feed');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiChatScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedArticlesAsync = ref.watch(filteredArticlesProvider);
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
                              _logger.info('Refreshing feed articles', category: 'Feed');
                              ref.read(feedArticlesProvider.notifier).refresh();
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
                  
                  // Topic Filter Chips
                  SizedBox(
                    height: 40,
                    child: Consumer(
                      builder: (context, topicRef, _) {
                        final selectedTopic = topicRef.watch(selectedTopicFilterProvider);
                        final topics = ['All Sources', 'Friends\' Adds', 'Tech', 'Science', 'AI', 'Politics', 'Business', 'Health', 'Climate', 'Innovation'];
                        
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: topics.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final topic = topics[index];
                            final isSelected = (selectedTopic == null && topic == 'All Sources') ||
                                             (selectedTopic == 'friends' && topic == 'Friends\' Adds') ||
                                             (selectedTopic == topic && topic != 'All Sources' && topic != 'Friends\' Adds');
                            
                            return FilterChip(
                              label: Text(topic),
                              selected: isSelected,
                              onSelected: (_) {
                                if (topic == 'All Sources') {
                                  topicRef.read(selectedTopicFilterProvider.notifier).state = null;
                                } else if (topic == 'Friends\' Adds') {
                                  topicRef.read(selectedTopicFilterProvider.notifier).state = 'friends';
                                } else {
                                  topicRef.read(selectedTopicFilterProvider.notifier).state = topic;
                                }
                              },
                              backgroundColor: isSelected 
                                  ? AppTheme.primaryBlue 
                                  : Colors.white,
                              selectedColor: AppTheme.primaryBlue,
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGray,
                                width: 1.5,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Article List (Scrollable)
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
                          const Text(
                            'No articles available',
                            style: TextStyle(
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

                  // Vertical page view of articles
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: articles.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                      print('📖 Viewing article ${index + 1}/${articles.length}');
                    },
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final isLiked = likedArticles.contains(article.id);
                      
                      return ArticleCard(
                        article: article,
                        isLiked: isLiked,
                        currentIndex: index + 1,
                        totalCount: articles.length,
                        onSwipeRight: () {
                          print('✓ Saving article: ${article.title}');
                          _showSaveToCollectionModal(context, article);
                        },
                        onSwipeLeft: () {
                          _logger.info('Rejecting article: ${article.title}', category: 'Feed');
                          // Mark article as rejected
                          ref.read(rejectedArticlesProvider.notifier).rejectArticle(article.id);
                          // Move to next article
                          if (index < articles.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        onAskAI: () {
                          _openAskAIWithArticle(context, article);
                        },
                        onLike: () {
                          ref.read(likedArticlesProvider.notifier).toggleLike(article.id);
                        },
                      );
                    },
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
                        ErrorMessageFormatter.format(error),
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
