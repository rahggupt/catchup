import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/article_model.dart';
import 'scrollable_article_card.dart';

/// Wraps an article card with horizontal swipe detection
/// Allows vertical scrolling through the list while detecting horizontal swipes
class SwipeableCardWrapper extends StatefulWidget {
  final ArticleModel article;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback? onAskAI;
  final bool isLiked;

  const SwipeableCardWrapper({
    super.key,
    required this.article,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.onAskAI,
    this.isLiked = false,
  });

  @override
  State<SwipeableCardWrapper> createState() => SwipeableCardWrapperState();
}

class SwipeableCardWrapperState extends State<SwipeableCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  bool _isContentScrolling = false;
  final double _minDragThreshold = 10.0;

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

  void _onPanUpdate(DragUpdateDetails details) {
    final newDragX = _dragX + details.delta.dx;
    final newDragY = _dragY + details.delta.dy;

    // Determine if this is primarily a horizontal or vertical gesture
    final isHorizontalGesture = newDragX.abs() > newDragY.abs();

    // Only block if content is scrolling AND this is a vertical gesture
    if (_isContentScrolling && !isHorizontalGesture) {
      return;
    }

    // Only update if moved more than min threshold or already dragging
    if (newDragX.abs() > _minDragThreshold ||
        newDragY.abs() > _minDragThreshold ||
        _isDragging) {
      setState(() {
        _dragX = newDragX;
        _dragY = newDragY;
        _isDragging = true;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalThreshold = screenWidth * 0.2; // 20% for left/right
    final velocityThreshold = 300.0;
    final velocity = details.velocity.pixelsPerSecond;

    // Check velocity for quick swipes
    if (velocity.dx.abs() > velocityThreshold &&
        _dragX.abs() > _minDragThreshold) {
      if (velocity.dx > 0) {
        _handleRightSwipe();
      } else {
        _handleLeftSwipe();
      }
      return;
    }

    // Check if primarily horizontal gesture
    final isHorizontalGesture = _dragX.abs() > _dragY.abs();

    if (isHorizontalGesture && _dragX.abs() > horizontalThreshold) {
      // Right or Left swipe
      if (_dragX > 0) {
        _handleRightSwipe();
      } else {
        _handleLeftSwipe();
      }
    } else {
      // Return to center with elastic bounce and haptic feedback
      HapticFeedback.lightImpact();
      _resetPosition();
    }
  }

  void _handleRightSwipe() {
    print('✓ Swiped RIGHT - Saving article: ${widget.article.title}');
    HapticFeedback.mediumImpact();

    // Animate off screen
    _animateOffScreen(true, () {
      widget.onSwipeRight();
      // Reset position after callback
      _resetPosition();
    });
  }

  void _handleLeftSwipe() {
    print('✗ Swiped LEFT - Skipping article');
    HapticFeedback.lightImpact();

    // Animate off screen
    _animateOffScreen(false, () {
      widget.onSwipeLeft();
      // Reset position after callback
      _resetPosition();
    });
  }

  void _animateOffScreen(bool toRight, VoidCallback onComplete) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = toRight ? screenWidth : -screenWidth;

    final animation = Tween<Offset>(
      begin: Offset(_dragX, _dragY),
      end: Offset(targetX, _dragY),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    animation.addListener(() {
      setState(() {
        _dragX = animation.value.dx;
        _dragY = animation.value.dy;
      });
    });

    _controller.forward().then((_) {
      onComplete();
      _controller.reset();
    });
  }

  void _resetPosition() {
    if (_dragX == 0 && _dragY == 0) return;

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

  /// Public method to reset card position (called from parent when modal cancelled)
  void resetCard() {
    if (mounted) {
      _resetPosition();
    }
  }
  
  /// Public method to force immediate reset (no animation)
  void forceReset() {
    if (mounted) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * 0.2;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..translate(_dragX, _dragY)
          ..scale(_isDragging ? 0.95 : 1.0) // Shrink while dragging
          ..rotateZ(_dragX / 150 * 0.35), // Rotation for feedback
        alignment: Alignment.center,
        child: Opacity(
          opacity: _isDragging
              ? (1.0 - (_dragX.abs() / 250)).clamp(0.3, 1.0)
              : 1.0,
          child: Stack(
            children: [
              // The actual article card
              Container(
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
                child: ScrollableArticleCard(
                  article: widget.article,
                  isLiked: widget.isLiked,
                  onScrollingChanged: (isScrolling) {
                    setState(() => _isContentScrolling = isScrolling);
                  },
                  onBookmark: widget.onSwipeRight,
                  onLike: () {}, // Handle in parent if needed
                  onShare: () {}, // Handle in parent if needed
                  onAskAI: widget.onAskAI,
                ),
              ),

              // Swipe indicators - Only show after 20% threshold
              if (_dragX > swipeThreshold) ...[
                // SAVE indicator (right swipe)
                Positioned(
                  left: 40,
                  top: MediaQuery.of(context).size.height * 0.35,
                  child: AnimatedOpacity(
                    opacity: ((_dragX - swipeThreshold) /
                            (screenWidth - swipeThreshold))
                        .clamp(0.0, 1.0),
                    duration: Duration.zero,
                    child: Transform.scale(
                      scale: 0.5 +
                          ((_dragX - swipeThreshold) /
                                  (screenWidth - swipeThreshold) *
                                  0.8)
                              .clamp(0.0, 0.8),
                      child: Transform.rotate(
                        angle: -0.3 +
                            ((_dragX - swipeThreshold) /
                                    (screenWidth - swipeThreshold) *
                                    0.1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.6),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green, width: 3),
                              ),
                              child: const Text(
                                'SAVE',
                                style: TextStyle(
                                  color: Colors.green,
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
              ] else if (_dragX < -swipeThreshold) ...[
                // SKIP indicator (left swipe)
                Positioned(
                  right: 40,
                  top: MediaQuery.of(context).size.height * 0.35,
                  child: AnimatedOpacity(
                    opacity: ((((-_dragX) - swipeThreshold) /
                            (screenWidth - swipeThreshold))
                        .clamp(0.0, 1.0)),
                    duration: Duration.zero,
                    child: Transform.scale(
                      scale: 0.5 +
                          ((((-_dragX) - swipeThreshold) /
                                      (screenWidth - swipeThreshold)) *
                                  0.8)
                              .clamp(0.0, 0.8),
                      child: Transform.rotate(
                        angle: 0.3 -
                            ((((-_dragX) - swipeThreshold) /
                                        (screenWidth - swipeThreshold)) *
                                    0.1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.6),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red, width: 3),
                              ),
                              child: const Text(
                                'SKIP',
                                style: TextStyle(
                                  color: Colors.red,
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
            ],
          ),
        ),
      ),
    );
  }
}

