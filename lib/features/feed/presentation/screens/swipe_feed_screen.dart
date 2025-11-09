import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/rss_feed_provider.dart';
import '../widgets/swipeable_card_wrapper.dart';
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
  
  void _showSaveToCollectionModal(BuildContext context, ArticleModel article) async {
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
    // The AI will use RAG to answer questions about this specific article
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AiChatScreen(),
      ),
    );
    
    // TODO: Pass article context to AI Chat for RAG
    print('📖 Opening Ask AI with article: ${article.title}');
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

                  // Scrollable list of articles
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final isLiked = likedArticles.contains(article.id);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SwipeableCardWrapper(
                          article: article,
                          isLiked: isLiked,
                          onSwipeRight: () {
                            print('✓ Saving article: ${article.title}');
                            _showSaveToCollectionModal(context, article);
                          },
                          onSwipeLeft: () {
                            print('✗ Skipping article: ${article.title}');
                            // Article stays in list, just provide feedback
                          },
                          onAskAI: () {
                            _openAskAIWithArticle(context, article);
                          },
                        ),
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
