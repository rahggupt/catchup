import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../providers/collections_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/collection_privacy_modal.dart';
import '../widgets/share_collection_modal.dart';
import '../widgets/edit_collection_modal.dart';
import '../widgets/collection_members_modal.dart';
import '../widgets/create_collection_modal.dart';
import 'collection_details_screen.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  String _searchQuery = '';
  String _sortOption = 'recent';

  List<CollectionModel> _filterAndSortCollections(List<CollectionModel> collections) {
    var filtered = collections;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((collection) {
        return collection.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply sorting
    switch (_sortOption) {
      case 'alphabetical':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'most_active':
        filtered.sort((a, b) => b.stats.articleCount.compareTo(a.stats.articleCount));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filtered;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = _searchQuery;
        return AlertDialog(
          title: const Text('Search Collections'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter collection name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = query);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(userCollectionsProvider);

    return collectionsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (collections) {
        final filteredCollections = _filterAndSortCollections(collections);
        return _buildContent(context, filteredCollections);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<CollectionModel> collections) {
    String sortLabel = _sortOption == 'recent' ? 'Recent' 
                     : _sortOption == 'alphabetical' ? 'Alphabetical' 
                     : 'Most Active';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Collections',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _showSearchDialog,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() => _sortOption = value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Text(sortLabel),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'recent',
                            child: Text('Recent'),
                          ),
                          const PopupMenuItem(
                            value: 'alphabetical',
                            child: Text('Alphabetical'),
                          ),
                          const PopupMenuItem(
                            value: 'most_active',
                            child: Text('Most Active'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Collections Grid
            Expanded(
              child: collections.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: AppTheme.textGray),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                            ? 'No collections yet' 
                            : 'No collections found',
                          style: const TextStyle(fontSize: 16, color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      return _CollectionCard(collection: collection);
                    },
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateCollectionModal(),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final CollectionModel collection;

  const _CollectionCard({required this.collection});

  void _shareCollection(BuildContext context) {
    // Show share modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareCollectionModal(collection: collection),
    );
  }

  void _editCollection(BuildContext context, WidgetRef ref) {
    // Show comprehensive edit modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCollectionModal(collection: collection),
    ).then((updated) {
      if (updated == true) {
        // Refresh collections if updated
        ref.invalidate(userCollectionsProvider);
      }
    });
  }
  
  void _showMembers(BuildContext context) {
    // Show members management modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionMembersModal(collection: collection),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionPrivacyModal(
        collection: collection,
      ),
    );
  }

  Future<void> _deleteCollection(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Are you sure you want to delete "${collection.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabaseService = SupabaseService();
      await supabaseService.deleteCollection(collection.id);
      
      // Refresh collections and stats
      ref.invalidate(userCollectionsProvider);
      ref.invalidate(profileUserProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection deleted'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to collection details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionDetailsScreen(collection: collection),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (collection.coverImage != null)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(collection.coverImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        collection.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteCollection(context, ref);
                        } else if (value == 'share') {
                          _shareCollection(context);
                        } else if (value == 'edit') {
                          _editCollection(context, ref);
                        } else if (value == 'members') {
                          _showMembers(context);
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
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stats
                Row(
                  children: [
                    const Icon(Icons.article_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('${collection.stats.articleCount}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('${collection.stats.chatCount}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.people_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('${collection.stats.contributorCount}'),
                  ],
                ),
                if (collection.preview != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    collection.preview!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _buildPrivacyBadge(collection.privacy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacyBadge(String privacy) {
    IconData icon;
    Color color;
    String label;
    
    switch (privacy) {
      case 'public':
        icon = Icons.public;
        color = Colors.green;
        label = 'Public';
        break;
      case 'invite':
        icon = Icons.people;
        color = Colors.orange;
        label = 'Invite-Only';
        break;
      default:
        icon = Icons.lock;
        color = AppTheme.primaryBlue;
        label = 'Private';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

