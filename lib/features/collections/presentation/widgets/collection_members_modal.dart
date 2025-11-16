import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../providers/collections_provider.dart';

class CollectionMembersModal extends ConsumerStatefulWidget {
  final CollectionModel collection;

  const CollectionMembersModal({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionMembersModal> createState() => _CollectionMembersModalState();
}

class _CollectionMembersModalState extends ConsumerState<CollectionMembersModal> {
  final LoggerService _logger = LoggerService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      // Check user permission
      final permission = await ref.read(userCollectionPermissionProvider(widget.collection.id).future);
      
      // Load members
      final supabaseService = SupabaseService();
      final members = await supabaseService.getCollectionMembers(widget.collection.id);
      
      if (mounted) {
        setState(() {
          _userRole = permission;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load members', category: 'Collections', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      _logger.info('Changing user role to: $newRole', category: 'Collections');
      
      await SupabaseConfig.client
          .from('collection_members')
          .update({'role': newRole})
          .eq('collection_id', widget.collection.id)
          .eq('user_id', userId);
      
      _logger.success('Role updated successfully', category: 'Collections');
      _loadData(); // Refresh
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role updated successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to update role', category: 'Collections', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $email from this collection?'),
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
      _logger.info('Removing member: $email', category: 'Collections');
      
      final supabaseService = SupabaseService();
      await supabaseService.removeCollectionMember(
        collectionId: widget.collection.id,
        userId: userId,
      );
      
      _logger.success('Member removed successfully', category: 'Collections');
      _loadData(); // Refresh
      
      // Refresh collections list
      ref.invalidate(userCollectionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to remove member', category: 'Collections', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _userRole == 'owner';
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Members (${_members.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Members List
          if (_isLoading)
            const Center(
              heightFactor: 3,
              child: CircularProgressIndicator(),
            )
          else if (_members.isEmpty)
            const Center(
              heightFactor: 3,
              child: Text(
                'No members yet',
                style: TextStyle(color: AppTheme.textGray),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final userId = member['user_id'] as String;
                  final role = member['role'] as String;
                  final userData = member['user'] as Map<String, dynamic>?;
                  final email = userData?['email'] as String? ?? 'Unknown';
                  final userName = userData?['raw_user_meta_data']?['first_name'] as String? ?? email.split('@')[0];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Name and email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Role badge/dropdown
                          if (isOwner && role != 'owner')
                            PopupMenuButton<String>(
                              initialValue: role,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getRoleColor(role)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getRoleLabel(role),
                                      style: TextStyle(
                                        color: _getRoleColor(role),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, size: 18, color: _getRoleColor(role)),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'viewer',
                                  child: Text('Viewer'),
                                ),
                                const PopupMenuItem(
                                  value: 'editor',
                                  child: Text('Editor'),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _removeMember(userId, email);
                                } else {
                                  _changeRole(userId, value);
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getRoleColor(role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRoleLabel(role),
                                style: TextStyle(
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Info
          if (!isOwner) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only the owner can manage members',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return AppTheme.primaryBlue;
      case 'editor':
        return Colors.green;
      case 'viewer':
        return Colors.orange;
      default:
        return AppTheme.textGray;
    }
  }

  String _getRoleLabel(String role) {
    return role[0].toUpperCase() + role.substring(1);
  }
}

