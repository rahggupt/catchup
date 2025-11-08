import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/article_model.dart';
import '../providers/feed_provider.dart';
import 'package:intl/intl.dart';

class SwipeableArticleCard extends ConsumerStatefulWidget {
  final ArticleModel article;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeableArticleCard({
    super.key,
    required this.article,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  ConsumerState<SwipeableArticleCard> createState() =>
      _SwipeableArticleCardState();
}

class _SwipeableArticleCardState extends ConsumerState<SwipeableArticleCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  bool _expanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const threshold = 100.0;

    if (_dragX.abs() > threshold) {
      // Swipe detected
      if (_dragX > 0) {
        // Swipe right - Save
        widget.onSwipeRight();
      } else {
        // Swipe left - Dismiss
        widget.onSwipeLeft();
      }
    }

    // Reset position
    setState(() {
      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragX / 1000;
    final opacity = 1.0 - (_dragX.abs() / 200).clamp(0.0, 0.5);
    final isLiked = ref.watch(likedArticlesProvider).contains(widget.article.id);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_dragX, _dragY * 0.5),
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                // Main Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Article Image
                      if (widget.article.imageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.article.imageUrl!,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: AppTheme.backgroundLight,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: AppTheme.backgroundLight,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                        ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Source and Time
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.article.source,
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${_getTimeAgo(widget.article.publishedAt)}',
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderGray),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.article.topic,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                widget.article.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Summary
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expanded = !_expanded;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.article.summary,
                                      maxLines: _expanded ? null : 4,
                                      overflow: _expanded
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textGray,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (!_expanded)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Tap to expand...',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_expanded && widget.article.author != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'By ${widget.article.author}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    // TODO: Open article in browser
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 44),
                                  ),
                                  child: const Text('Read Full Article'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Footer Actions
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked
                                    ? AppTheme.errorRed
                                    : AppTheme.textGray,
                              ),
                              onPressed: () {
                                ref
                                    .read(likedArticlesProvider.notifier)
                                    .toggleLike(widget.article.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bookmark_border,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                // TODO: Quick save
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                // TODO: Comment or discuss
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.share_outlined,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                // TODO: Share article
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Swipe Indicators
                if (_isDragging && _dragX < -50)
                  Positioned(
                    left: 24,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                if (_isDragging && _dragX > 50)
                  Positioned(
                    right: 24,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

