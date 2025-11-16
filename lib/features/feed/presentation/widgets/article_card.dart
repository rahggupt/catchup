import 'package:flutter/material.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/logger_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Simplified article card with horizontal swipe gestures
class ArticleCard extends StatefulWidget {
  final ArticleModel article;
  final bool isLiked;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onAskAI;
  final VoidCallback onLike;

  const ArticleCard({
    super.key,
    required this.article,
    required this.isLiked,
    required this.currentIndex,
    required this.totalCount,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onAskAI,
    required this.onLike,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> with SingleTickerProviderStateMixin {
  final LoggerService _logger = LoggerService();
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * 0.3; // 30% of screen width

    // Horizontal swipe detection
    if (_dragX.abs() > swipeThreshold) {
      if (_dragX > 0) {
        // Swipe right - Save
        _logger.info('Swipe right detected on article: ${widget.article.title}', category: 'Feed');
        _animateOffScreen(true);
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onSwipeRight();
          _resetPosition();
        });
      } else {
        // Swipe left - Reject
        _logger.info('Swipe left detected (reject) on article: ${widget.article.title}', category: 'Feed');
        _animateOffScreen(false);
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onSwipeLeft();
        });
      }
    } else {
      // Reset if not enough swipe
      _logger.info('Swipe cancelled, returning to center', category: 'Feed');
      _resetPosition();
    }
  }

  void _animateOffScreen(bool isRight) {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _dragX = isRight ? screenWidth : -screenWidth;
      _isDragging = false;
    });
  }

  void _resetPosition() {
    setState(() {
      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = _dragX / screenWidth * 0.2; // Subtle rotation
    final opacity = 1.0 - (_dragX.abs() / screenWidth * 0.5).clamp(0.0, 0.5);
    final scale = 1.0 - (_dragX.abs() / screenWidth * 0.1).clamp(0.0, 0.1);

    // Show indicators based on swipe direction
    final showRightIndicator = _dragX > 50;
    final showLeftIndicator = _dragX < -50;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Main card with transform
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          // Article image
                          if (widget.article.imageUrl != null)
                            SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: widget.article.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.borderGray.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.borderGray.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                              ),
                            ),

                          // Content area (scrollable)
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Source and date
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          widget.article.source,
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (widget.article.publishedAt != null)
                                        Text(
                                          _formatDate(widget.article.publishedAt!),
                                          style: const TextStyle(
                                            color: AppTheme.textGray,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Title
                                  Text(
                                    widget.article.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Author
                                  if (widget.article.author != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'By ${widget.article.author}',
                                        style: const TextStyle(
                                          color: AppTheme.textGray,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),

                                  // Summary
                                  Text(
                                    widget.article.summary,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textDark,
                                      height: 1.6,
                                    ),
                                  ),
                                  
                                  // Content (if available)
                                  if (widget.article.content != null && widget.article.content!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Text(
                                        widget.article.content!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textDark,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 24),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Like button
                                      IconButton(
                                        onPressed: widget.onLike,
                                        icon: Icon(
                                          widget.isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: widget.isLiked ? AppTheme.errorRed : AppTheme.textGray,
                                          size: 28,
                                        ),
                                      ),

                                      // Ask AI button
                                      ElevatedButton.icon(
                                        onPressed: widget.onAskAI,
                                        icon: const Icon(Icons.psychology, size: 20),
                                        label: const Text('Ask AI'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.secondaryPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Article counter
                                  Center(
                                    child: Text(
                                      '${widget.currentIndex} of ${widget.totalCount}',
                                      style: const TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right swipe indicator (Save)
          if (showRightIndicator)
            Positioned(
              left: 40,
              top: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

          // Left swipe indicator (Reject)
          if (showLeftIndicator)
            Positioned(
              right: 40,
              top: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorRed.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

