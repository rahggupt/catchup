import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../providers/collections_provider.dart';
import '../widgets/edit_collection_modal.dart';
import '../widgets/collection_members_modal.dart';
import '../widgets/share_collection_modal.dart';

class CollectionDetailsScreen extends ConsumerStatefulWidget {
  final CollectionModel collection;

  const CollectionDetailsScreen({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionDetailsScreen> createState() => _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends ConsumerState<CollectionDetailsScreen> {
  final LoggerService _logger = LoggerService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await ref.read(userCollectionPermissionProvider(widget.collection.id).future);
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  Future<void> _removeArticle(BuildContext context, String articleId) async {
    if (_userRole == 'viewer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to remove articles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Article'),
        content: const Text('Remove this article from the collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _logger.info('Removing article from collection', category: 'Collections');
      
      final supabaseService = SupabaseService();
      await supabaseService.removeArticleFromCollection(
        collectionId: widget.collection.id,
        articleId: articleId,
      );
      
      _logger.success('Article removed successfully', category: 'Collections');
      
      // Refresh the realtime provider
      ref.invalidate(collectionArticlesRealtimeProvider(widget.collection.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article removed'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to remove article', category: 'Collections', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove article: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final articlesStream = ref.watch(collectionArticlesRealtimeProvider(widget.collection.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.collection.name),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ShareCollectionModal(collection: widget.collection),
              );
            },
          ),
          // More menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit' && (_userRole == 'owner' || _userRole == 'editor')) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => EditCollectionModal(collection: widget.collection),
                );
              } else if (value == 'members') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CollectionMembersModal(collection: widget.collection),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 12),
                    Text('Manage Members'),
                  ],
                ),
              ),
              if (_userRole == 'owner' || _userRole == 'editor')
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 12),
                      Text('Edit Collection'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collection header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                if (widget.collection.coverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.collection.coverImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: AppTheme.backgroundLight,
                        child: const Icon(Icons.collections_bookmark, size: 48),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Collection stats
                Row(
                  children: [
                    _buildStatChip(Icons.article, '${widget.collection.stats.articleCount}'),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.people, '${widget.collection.stats.contributorCount}'),
                    const SizedBox(width: 8),
                    _buildPrivacyBadge(widget.collection.privacy),
                  ],
                ),

                // Description
                if (widget.collection.preview != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.collection.preview!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Articles header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Articles',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Articles list
          Expanded(
            child: articlesStream.when(
              data: (articles) {
                if (articles.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: AppTheme.textGray),
                        SizedBox(height: 16),
                        Text(
                          'No articles yet',
                          style: TextStyle(fontSize: 16, color: AppTheme.textGray),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Articles you save will appear here',
                          style: TextStyle(fontSize: 14, color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final articleData = articles[index];
                    final article = articleData['article'] as Map<String, dynamic>?;
                    
                    if (article == null) return const SizedBox.shrink();

                    return _ArticleCard(
                      article: article,
                      canRemove: _userRole == 'owner' || _userRole == 'editor',
                      onRemove: () => _removeArticle(context, article['id'] as String),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading articles',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textGray),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(String privacy) {
    IconData icon;
    Color color;
    
    switch (privacy) {
      case 'public':
        icon = Icons.public;
        color = Colors.green;
        break;
      case 'invite':
        icon = Icons.people;
        color = Colors.orange;
        break;
      default:
        icon = Icons.lock;
        color = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            privacy == 'invite' ? 'Invite' : privacy[0].toUpperCase() + privacy.substring(1),
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool canRemove;
  final VoidCallback onRemove;

  const _ArticleCard({
    required this.article,
    required this.canRemove,
    required this.onRemove,
  });

  Future<void> _openArticleWebview(BuildContext context) async {
    final logger = LoggerService();
    final url = article['url'] as String?;
    
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article URL not available'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    
    logger.info('Opening article URL: $url', category: 'Collections');
    
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        logger.success('Opened article in external browser', category: 'Collections');
      } else {
        logger.error('Could not launch URL: $url', category: 'Collections');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open article'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.error('Error launching URL', category: 'Collections', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening article'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = article['title'] as String? ?? 'Untitled';
    final source = article['source'] as String? ?? 'Unknown';
    final publishedAt = article['published_at'] as String?;
    final imageUrl = article['image_url'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openArticleWebview(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.backgroundLight,
                      child: const Icon(Icons.article, color: AppTheme.textGray),
                    ),
                  ),
                ),
              if (imageUrl != null) const SizedBox(width: 12),

              // Article info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    if (publishedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(publishedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Remove button
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove from collection',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

