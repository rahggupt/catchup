import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../providers/collections_provider.dart';

class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String token;

  const AcceptInviteScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final LoggerService _logger = LoggerService();
  bool _isLoading = true;
  bool _isAccepting = false;
  Map<String, dynamic>? _collectionData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollectionPreview();
  }

  Future<void> _loadCollectionPreview() async {
    try {
      _logger.info('Loading collection preview for token: ${widget.token}', category: 'Collections');
      
      final supabaseService = SupabaseService();
      final data = await supabaseService.getCollectionByToken(widget.token);
      
      if (data == null) {
        setState(() {
          _error = 'Invalid or expired invite link';
          _isLoading = false;
        });
        _logger.warning('Invalid token provided', category: 'Collections');
        return;
      }
      
      setState(() {
        _collectionData = data;
        _isLoading = false;
      });
      
      _logger.success('Collection preview loaded', category: 'Collections');
    } catch (e, stackTrace) {
      _logger.error('Failed to load collection preview', category: 'Collections', error: e, stackTrace: stackTrace);
      setState(() {
        _error = 'Failed to load collection: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvite() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      // Redirect to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to accept this invite'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    setState(() => _isAccepting = true);
    
    try {
      _logger.info('Accepting collection invite', category: 'Collections');
      
      final supabaseService = SupabaseService();
      
      // Add user as member
      await supabaseService.addCollectionMember(
        collectionId: _collectionData!['id'],
        userId: user.id,
        role: 'viewer', // Default role for shared collections
      );
      
      // Refresh collections list
      ref.invalidate(userCollectionsProvider);
      
      _logger.success('Collection invite accepted successfully', category: 'Collections');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the collection!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        // Navigate to collections screen
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to accept invite', category: 'Collections', error: e, stackTrace: stackTrace);
      
      setState(() => _isAccepting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Collection Invite'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildPreviewView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewView() {
    final name = _collectionData!['name'] as String;
    final stats = _collectionData!['stats'] as Map<String, dynamic>?;
    final articleCount = stats?['article_count'] ?? 0;
    final contributorCount = stats?['contributor_count'] ?? 1;
    final privacy = _collectionData!['privacy'] as String;
    final ownerEmail = _collectionData!['owner']?['email'] as String? ?? 'Unknown';
    final preview = _collectionData!['preview'] as String?;
    final coverImage = _collectionData!['cover_image'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image
          if (coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                coverImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppTheme.backgroundLight,
                  child: const Icon(Icons.collections_bookmark, size: 64),
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.collections_bookmark,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          
          const SizedBox(height: 24),

          // Collection Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Owner
          Row(
            children: [
              const Text(
                'Created by ',
                style: TextStyle(color: AppTheme.textGray),
              ),
              Text(
                ownerEmail,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatChip(Icons.article_outlined, '$articleCount articles'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.people_outline, '$contributorCount members'),
              const SizedBox(width: 12),
              _buildStatChip(
                privacy == 'public' ? Icons.public : Icons.people,
                privacy == 'public' ? 'Public' : 'Invite-only',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          if (preview != null) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Info card
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
                    Icon(Icons.info_outline, size: 20, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• You\'ll be added as a viewer\n'
                  '• View all articles in this collection\n'
                  '• Chat with AI about the collection\n'
                  '• Collaborate with other members',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Accept Button
          ElevatedButton(
            onPressed: _isAccepting ? null : _acceptInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isAccepting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accept Invite & Join Collection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Decline Button
          OutlinedButton(
            onPressed: _isAccepting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textGray),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

