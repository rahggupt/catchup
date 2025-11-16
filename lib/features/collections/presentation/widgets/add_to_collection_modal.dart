import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../providers/collections_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class AddToCollectionModal extends ConsumerStatefulWidget {
  final ArticleModel article;

  const AddToCollectionModal({
    super.key,
    required this.article,
  });

  @override
  ConsumerState<AddToCollectionModal> createState() => _AddToCollectionModalState();
}

class _AddToCollectionModalState extends ConsumerState<AddToCollectionModal> {
  String? selectedCollectionId;
  bool _isLoading = false;
  final _newCollectionController = TextEditingController();
  bool _showCreateNew = false;

  @override
  void dispose() {
    _newCollectionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (selectedCollectionId == null && !_showCreateNew) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check if article ID is valid (mock IDs are just numbers like "1", "2", etc.)
      final isArticleMock = !widget.article.id.contains('-') && widget.article.id.length < 5;
      
      if (isArticleMock) {
        // Mock article - just show success without saving to DB
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article saved! (Mock mode - add real articles to use this feature)'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final supabaseService = SupabaseService();

      String collectionId;

      if (_showCreateNew) {
        // Validate collection name
        final collectionName = _newCollectionController.text.trim();
        if (collectionName.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a collection name.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        // Create new collection
        print('📝 Creating new collection: $collectionName');
        print('   Owner ID: ${user.id}');
        print('   Privacy: private');
        
        try {
          final newCollection = await supabaseService.createCollection(
            name: collectionName,
            ownerId: user.id,
            privacy: 'private',
            preview: widget.article.imageUrl,
          );
          collectionId = newCollection.id;
          print('✅ Collection created successfully: ${newCollection.id}');
        } catch (createError) {
          print('❌ Error creating collection: $createError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create collection: ${createError.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        // Use the selected collection (all real collections have UUID format)
        collectionId = selectedCollectionId!;
        print('📚 Using existing collection: $collectionId');
      }

      // First, save the article to database (if not already there)
      print('💾 Saving article to database: ${widget.article.id}');
      print('   Article title: ${widget.article.title}');
      print('   Article source: ${widget.article.source}');
      try {
        await supabaseService.createArticle(widget.article);
        print('✅ Article saved successfully');
      } catch (e) {
        // Article might already exist, that's OK
        print('⚠️ Article might already exist: $e');
      }
      
      // Add article to collection
      print('📚 Adding article to collection');
      print('   Collection ID: $collectionId');
      print('   Article ID: ${widget.article.id}');
      print('   Added by: ${user.id}');
      
      try {
        await supabaseService.addArticleToCollection(
          collectionId: collectionId,
          articleId: widget.article.id,
          addedBy: user.id,
        );
        print('✅ Article added to collection successfully');
      } catch (addError) {
        print('❌ Error adding article to collection: $addError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add article: ${addError.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Refresh collections and profile stats
      print('🔄 Refreshing collections and profile stats');
      ref.invalidate(userCollectionsProvider);
      ref.invalidate(profileUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article added to collection! Refreshing stats...'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Log technical error for debugging
      print('❌ Error saving article to collection: $e');
      
      if (mounted) {
        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save article. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(userCollectionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderGray)),
            ),
            child: Row(
              children: [
                const Text(
                  'Add to Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: collectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading collections: $error'),
              ),
              data: (collections) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article Preview
                        Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (widget.article.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.article.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: AppTheme.borderGray,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.article.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.article.source,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                        const SizedBox(height: 24),

                        // Create New Collection
                        if (_showCreateNew) ...[
                          TextField(
                            controller: _newCollectionController,
                            decoration: const InputDecoration(
                              labelText: 'Collection Name',
                              hintText: 'e.g., AI Research',
                            ),
                            autofocus: true,
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showCreateNew = false;
                                _newCollectionController.clear();
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ] else ...[
                          // Create New Button
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _showCreateNew = true);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Collection'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Existing Collections
                          if (collections.isNotEmpty) ...[
                            const Text(
                              'Your Collections',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...collections.map((collection) {
                              final isSelected = selectedCollectionId == collection.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCollectionId = collection.id;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryBlue.withOpacity(0.1)
                                        : AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (collection.preview != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            collection.preview!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 50,
                                              height: 50,
                                              color: AppTheme.borderGray,
                                              child: const Icon(Icons.folder),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppTheme.borderGray,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.folder),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              collection.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${collection.stats.articleCount} articles · ${collection.privacy}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppTheme.primaryBlue,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No collections yet.\nCreate one to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textGray),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderGray)),
            ),
            child: ElevatedButton(
              onPressed: (selectedCollectionId != null || _showCreateNew)
                  ? (_isLoading ? null : _handleSave)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_showCreateNew ? 'Create & Add' : 'Add to Collection'),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

