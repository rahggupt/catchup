import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../providers/collections_provider.dart';

class CollectionPrivacyModal extends ConsumerStatefulWidget {
  final CollectionModel collection;

  const CollectionPrivacyModal({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionPrivacyModal> createState() =>
      _CollectionPrivacyModalState();
}

class _CollectionPrivacyModalState
    extends ConsumerState<CollectionPrivacyModal> {
  late String _selectedPrivacy;
  bool _isLoading = false;
  String? _shareToken;
  List<Map<String, dynamic>> _members = [];
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPrivacy = widget.collection.privacy;
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final supabaseService = SupabaseService();
      final members = await supabaseService.getCollectionMembers(
        widget.collection.id,
      );
      setState(() {
        _members = members;
      });
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _updatePrivacy(String privacy) async {
    setState(() => _isLoading = true);
    
    try {
      final supabaseService = SupabaseService();
      await supabaseService.updateCollectionPrivacy(
        widget.collection.id,
        privacy,
      );
      
      setState(() {
        _selectedPrivacy = privacy;
      });
      
      // Refresh collections
      ref.invalidate(userCollectionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy updated successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      print('Error updating privacy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update privacy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateShareLink() async {
    setState(() => _isLoading = true);
    
    try {
      final supabaseService = SupabaseService();
      final token = await supabaseService.generateShareableLink(
        widget.collection.id,
      );
      
      setState(() {
        _shareToken = token;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share link generated!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      print('Error generating share link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyShareLink() async {
    if (_shareToken == null) return;
    
    // Use custom scheme for direct app opening (no web server needed)
    final shareLink = 'catchup://c/$_shareToken';
    
    await Clipboard.setData(ClipboardData(text: shareLink));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final supabaseService = SupabaseService();
      await supabaseService.sendCollectionInvite(
        collectionId: widget.collection.id,
        inviterId: user.id,
        inviteeEmail: email,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      
      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite sent to $email'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      print('Error sending invite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send invite'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final supabaseService = SupabaseService();
      await supabaseService.removeCollectionMember(
        collectionId: widget.collection.id,
        userId: userId,
      );
      
      await _loadMembers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      print('Error removing member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Collection Privacy',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Privacy Options
                const Text(
                  'Privacy Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildPrivacyOption(
                  'private',
                  'Private',
                  'Only you can access this collection',
                  Icons.lock,
                ),
                _buildPrivacyOption(
                  'public',
                  'Shareable Link',
                  'Anyone with the link can view',
                  Icons.link,
                ),
                _buildPrivacyOption(
                  'invite',
                  'Invite-Only',
                  'Only invited users can access',
                  Icons.people,
                ),

                // Share Link Section (only for public)
                if (_selectedPrivacy == 'public') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Share Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_shareToken == null) ...[
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateShareLink,
                      icon: const Icon(Icons.link),
                      label: const Text('Generate Share Link'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'catchup://c/$_shareToken',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _copyShareLink,
                            tooltip: 'Copy link',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Invite Section (only for invite-only)
                if (_selectedPrivacy == 'invite') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Invite People',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'Enter email address',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendInvite,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],

                // Members Section
                if (_selectedPrivacy != 'private' && _members.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._members.map((member) {
                    final userEmail = member['user']?['email'] ?? 'Unknown';
                    final role = member['role'] ?? 'viewer';
                    final userId = member['user_id'];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              userEmail[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (role != 'owner')
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () => _removeMember(userId),
                              tooltip: 'Remove member',
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedPrivacy == value;
    
    return GestureDetector(
      onTap: () => _updatePrivacy(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
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
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

