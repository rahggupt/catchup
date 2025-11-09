import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _SwipeFeedScreenState extends ConsumerState<SwipeFeedScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  bool _isContentScrolling = false;
  final double _minDragThreshold = 30.0; // 30px dead zone
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
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

  void _openAskAIWithArticle(BuildContext context, ArticleModel article) {
    // Navigate to AI Chat screen with article context
    // The AI will use RAG to answer questions about this specific article
    Navigator.of(context).pushNamed(
      '/ai-chat',
      arguments: {
        'article': article,
        'mode': 'rag', // RAG mode without collection selection
      },
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Don't allow horizontal swipe if content is scrolling
    if (_isContentScrolling) {
      return;
    }
    
    final newDragX = _dragX + details.delta.dx;
    final newDragY = _dragY + details.delta.dy;
    
    // Only update if moved more than min threshold or already dragging
    if (newDragX.abs() > _minDragThreshold || newDragY.abs() > _minDragThreshold || _isDragging) {
      setState(() {
        _dragX = newDragX;
        _dragY = newDragY;
        _isDragging = true;
      });
    }
  }

  void _onPanEnd(DragEndDetails details, List<ArticleModel> articles) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.2; // 20% of screen width
    final velocityThreshold = 300.0;
    final velocity = details.velocity.pixelsPerSecond;
    final currentIndex = ref.read(currentArticleIndexProvider);
    
    if (currentIndex >= articles.length) {
      _resetPosition();
      return;
    }

    final article = articles[currentIndex];

    // Check velocity for quick swipes
    if (velocity.dx.abs() > velocityThreshold && _dragX.abs() > _minDragThreshold) {
      if (velocity.dx > 0) {
        _handleRightSwipe(article);
      } else {
        _handleLeftSwipe();
      }
      return;
    }
    
    // Check distance for deliberate swipes
    if (_dragX.abs() > threshold) {
      // Right or Left swipe
      if (_dragX > 0) {
        _handleRightSwipe(article);
      } else {
        _handleLeftSwipe();
      }
    } else if (_dragY.abs() > threshold) {
      // Up or Down swipe
      if (_dragY < 0) {
        _handleUpSwipe();
      } else {
        _handleDownSwipe();
      }
    } else {
      // Return to center with elastic bounce and haptic feedback
      HapticFeedback.lightImpact();
      _resetPosition();
    }
  }

  void _handleRightSwipe(ArticleModel article) {
    print('✓ Swiped RIGHT - Saving article: ${article.title}');
    HapticFeedback.mediumImpact();
    
    // Animate off screen
    _animateOffScreen(true, () {
      _moveToNextArticle();
      // Show modal after a brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          _showSaveToCollectionModal(context, article);
        }
      });
    });
  }

  void _handleLeftSwipe() {
    print('✗ Swiped LEFT - Skipping article');
    HapticFeedback.lightImpact();
    
    // Animate off screen
    _animateOffScreen(false, () {
      _moveToNextArticle();
    });
  }

  void _handleUpSwipe() {
    print('↑ Swiped UP - Next article');
    HapticFeedback.selectionClick();
    
    _animateOffScreen(false, () {
      _moveToNextArticle();
    });
  }

  void _handleDownSwipe() {
    print('↓ Swiped DOWN - Previous article');
    final currentIndex = ref.read(currentArticleIndexProvider);
    if (currentIndex > 0) {
      HapticFeedback.selectionClick();
      _resetPosition();
      ref.read(currentArticleIndexProvider.notifier).state = currentIndex - 1;
    } else {
      _resetPosition();
    }
  }

  void _moveToNextArticle() {
    final currentIndex = ref.read(currentArticleIndexProvider);
    ref.read(currentArticleIndexProvider.notifier).state = currentIndex + 1;
  }

  void _animateOffScreen(bool right, VoidCallback onComplete) {
    final targetX = right ? 500.0 : -500.0;
    
    final animation = Tween<double>(
      begin: _dragX,
      end: targetX,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    animation.addListener(() {
      setState(() {
        _dragX = animation.value;
      });
    });

    _controller.forward().then((_) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
      _controller.reset();
      onComplete();
    });
  }

  void _resetPosition() {
    final animation = Tween<Offset>(
      begin: Offset(_dragX, _dragY),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    animation.addListener(() {
      setState(() {
        _dragX = animation.value.dx;
        _dragY = animation.value.dy;
      });
    });

    _controller.forward().then((_) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
      _controller.reset();
    });
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
                                topicRef.read(currentArticleIndexProvider.notifier).state = 0;
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

                  // Show current article with custom gesture swipe
                  final article = articles[currentIndex];
                  final isLiked = likedArticles.contains(article.id);
                  final screenWidth = MediaQuery.of(context).size.width;
                  
                  return Stack(
                    children: [
                      // Swipeable Card with GestureDetector
                      GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: (details) => _onPanEnd(details, articles),
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..translate(_dragX, _dragY)
                            ..scale(_isDragging ? 0.95 : 1.0) // Shrink while dragging
                            ..rotateZ(_dragX / 150 * 0.35), // More rotation for better feedback
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: _isDragging 
                                ? (1.0 - (_dragX.abs() / 250)).clamp(0.3, 1.0) // More dramatic fade
                                : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.1),
                                    blurRadius: _isDragging ? 30 : 10,
                                    spreadRadius: _isDragging ? 5 : 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: ScrollableArticleCard(
                                  article: article,
                                  isLiked: isLiked,
                                  onScrollingChanged: (isScrolling) {
                                    setState(() => _isContentScrolling = isScrolling);
                                  },
                                  onBookmark: () {
                                    _showSaveToCollectionModal(context, article);
                                  },
                                  onLike: () {
                                    ref.read(likedArticlesProvider.notifier).toggleLike(article.id);
                                  },
                                  onShare: () {
                                    _shareArticle(article);
                                  },
                                  onAskAI: () {
                                    _openAskAIWithArticle(context, article);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Swipe indicators - Only show after 20% threshold
                      if (_dragX > screenWidth * 0.2) ...[
                        // Swiping RIGHT - Show SAVE indicator
                        Positioned(
                          left: 40,
                          top: MediaQuery.of(context).size.height / 2 - 100,
                          child: AnimatedOpacity(
                            opacity: ((_dragX - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2)).clamp(0.0, 1.0),
                            duration: Duration.zero,
                            child: Transform.scale(
                              scale: 0.5 + ((_dragX - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2) * 0.8).clamp(0.0, 0.8),
                              child: Transform.rotate(
                                angle: -0.3 + ((_dragX - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2) * 0.1),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.successGreen.withOpacity(0.6),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.bookmark,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.successGreen, width: 3),
                                      ),
                                      child: const Text(
                                        'SAVE',
                                        style: TextStyle(
                                          color: AppTheme.successGreen,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else if (_dragX < -screenWidth * 0.2) ...[
                        // Swiping LEFT - Show SKIP indicator
                        Positioned(
                          right: 40,
                          top: MediaQuery.of(context).size.height / 2 - 100,
                          child: AnimatedOpacity(
                            opacity: (((-_dragX) - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2)).clamp(0.0, 1.0),
                            duration: Duration.zero,
                            child: Transform.scale(
                              scale: 0.5 + ((((-_dragX) - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2)) * 0.8).clamp(0.0, 0.8),
                              child: Transform.rotate(
                                angle: 0.3 - ((((-_dragX) - screenWidth * 0.2) / (screenWidth - screenWidth * 0.2)) * 0.1),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.errorRed.withOpacity(0.6),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.errorRed, width: 3),
                                      ),
                                      child: const Text(
                                        'SKIP',
                                        style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Progress Indicator at Bottom-Right
                      Positioned(
                        bottom: 80,
                        right: 20,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${currentIndex + 1}/${articles.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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

