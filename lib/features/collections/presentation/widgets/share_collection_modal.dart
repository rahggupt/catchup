import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';

class ShareCollectionModal extends ConsumerStatefulWidget {
  final CollectionModel collection;

  const ShareCollectionModal({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<ShareCollectionModal> createState() => _ShareCollectionModalState();
}

class _ShareCollectionModalState extends ConsumerState<ShareCollectionModal> {
  final LoggerService _logger = LoggerService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _shareableLink;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
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
      final members = await supabaseService.getCollectionMembers(widget.collection.id);
      if (mounted) {
        setState(() => _members = members);
      }
    } catch (e) {
      _logger.error('Failed to load collection members', category: 'Collections', error: e);
    }
  }

  Future<void> _generateLink() async {
    setState(() => _isLoading = true);
    try {
      _logger.info('Generating shareable link for collection: ${widget.collection.name}', category: 'Collections');
      
      final supabaseService = SupabaseService();
      final link = await supabaseService.generateShareableLink(widget.collection.id);
      
      setState(() => _shareableLink = link);
      _logger.success('Shareable link generated successfully', category: 'Collections');
    } catch (e) {
      _logger.error('Failed to generate shareable link', category: 'Collections', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyLink() async {
    if (_shareableLink != null) {
      await Clipboard.setData(ClipboardData(text: _shareableLink!));
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
  }

  Future<void> _shareLink() async {
    if (_shareableLink != null) {
      await Share.share(
        '📰 Check out my collection "${widget.collection.name}" on CatchUp!\n\n'
        '👉 Click to open:\n$_shareableLink\n\n'
        '📲 Don\'t have CatchUp? Let me know!',
        subject: 'Collection Shared: ${widget.collection.name}',
      );
    }
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      _logger.info('Sending invite to: $email', category: 'Collections');
      
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final supabaseService = SupabaseService();
      await supabaseService.sendCollectionInvite(
        collectionId: widget.collection.id,
        inviterId: user.id,
        inviteeEmail: email,
        expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 day expiry
      );

      _emailController.clear();
      _logger.success('Invite sent successfully', category: 'Collections');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite sent to $email'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      _logger.error('Failed to send invite', category: 'Collections', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invite: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = widget.collection.privacy == 'private';
    final isInvite = widget.collection.privacy == 'invite';
    final isPublic = widget.collection.privacy == 'public';

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
              const Icon(Icons.share, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Share "${widget.collection.name}"',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Privacy warning for private collections
          if (isPrivate)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, size: 20, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Private Collection',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This collection is private. Change privacy to "Invite" or "Public" to share with others.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to edit collection screen
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change Privacy Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

          // Invite-only sharing
          if (isInvite) ...[
            const Text(
              'Invite by Email',
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
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],

          // Public sharing link
          if (isPublic || isInvite) ...[
            const Text(
              'Share Link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_shareableLink == null) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateLink,
                icon: const Icon(Icons.link),
                label: const Text('Generate Shareable Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        _shareableLink!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: _copyLink,
                      tooltip: 'Copy link',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareLink,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share via...'),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // Current members
          if (_members.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Members (${_members.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final email = member['user']?['email'] ?? 'Unknown';
                  final role = member['role'] ?? 'viewer';
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Text(
                        email[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryBlue),
                      ),
                    ),
                    title: Text(email),
                    subtitle: Text(role.toString().toUpperCase()),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

