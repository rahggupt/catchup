import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/article_model.dart';

/// Scrollable article card for vertical feed
class ScrollableArticleCard extends StatefulWidget {
  final ArticleModel article;
  final VoidCallback onBookmark;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback? onAskAI;
  final bool isLiked;
  final ValueChanged<bool>? onScrollingChanged;

  const ScrollableArticleCard({
    super.key,
    required this.article,
    required this.onBookmark,
    required this.onLike,
    required this.onShare,
    this.onAskAI,
    this.isLiked = false,
    this.onScrollingChanged,
  });

  @override
  State<ScrollableArticleCard> createState() => _ScrollableArticleCardState();
}

class _ScrollableArticleCardState extends State<ScrollableArticleCard> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only report as scrolling if the user is actively dragging the content
    // Not just when the scroll position changes slightly
    final isScrolling = _scrollController.position.isScrollingNotifier.value;
    final hasScrolled = _scrollController.offset > 10; // Only if scrolled more than 10px
    
    final actuallyScrolling = isScrolling && hasScrolled;
    if (actuallyScrolling != _isScrolling) {
      setState(() => _isScrolling = actuallyScrolling);
      widget.onScrollingChanged?.call(actuallyScrolling);
    }
  }

  Future<void> _openArticle() async {
    try {
      final uri = Uri.parse(widget.article.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Cannot launch URL: ${widget.article.url}');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Image
          GestureDetector(
            onTap: _openArticle,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.article.imageUrl!,
                      height: 200,
                      width: double.infinity,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: AppTheme.textGray.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.article.source,
                              style: TextStyle(
                                color: AppTheme.textGray.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: AppTheme.backgroundLight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article,
                            size: 48,
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.article.source,
                            style: TextStyle(
                              color: AppTheme.textGray.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Article Content - NOW SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and Topic
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.article.source,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.article.topic,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryPurple,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getTimeAgo(widget.article.publishedAt ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Ask AI Button - moved here from bottom action bar
                        InkWell(
                          onTap: widget.onAskAI ?? () {},
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.secondaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppTheme.secondaryPurple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ask AI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    GestureDetector(
                      onTap: _openArticle,
                      child: Text(
                        widget.article.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Summary - NO maxLines limit, fully scrollable
                    GestureDetector(
                      onTap: _openArticle,
                      child: Text(
                        widget.article.summary,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGray.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                    ),
                    
                    // Author
                    if (widget.article.author != null && widget.article.author!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'By ${widget.article.author}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textGray.withOpacity(0.7),
                          ),
                        ),
                      ),
                    
                    // Read Full Article Button
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openArticle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.primaryBlue),
                        label: const Text(
                          'Read Full Article',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.textGray.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: widget.isLiked ? Colors.red : AppTheme.textGray,
                  onTap: widget.onLike,
                ),
                _ActionButton(
                  icon: Icons.bookmark_border,
                  label: 'Save',
                  color: AppTheme.primaryBlue,
                  onTap: widget.onBookmark,
                ),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: AppTheme.textGray,
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

