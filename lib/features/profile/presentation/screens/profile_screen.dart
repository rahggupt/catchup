import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../feed/presentation/widgets/add_source_modal.dart';
import '../widgets/ai_config_modal.dart';
import '../../../debug/presentation/screens/debug_logs_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileUserProvider);
    final sourcesAsync = ref.watch(userSourcesProvider);
    
    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        final sources = sourcesAsync.maybeWhen(
          data: (data) => data,
          orElse: () => [],
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user.bio != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Stats Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.article_outlined,
                            label: 'Articles',
                            value: user.stats.articles,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.folder_outlined,
                            label: 'Collections',
                            value: user.stats.collections,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.chat_bubble_outline,
                            label: 'Chats',
                            value: user.stats.chats,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Sources & Topics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sources & Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddSourceModal(),
                            );
                          },
                          child: const Text('Add More'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Only show active sources (hide disabled ones)
                    ...sources.where((s) => s.active).map((source) => _SourceCard(source: source)),
                    
                    // Show disabled sources separately if any
                    if (sources.any((s) => !s.active)) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Disabled Sources',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sources.where((s) => !s.active).map((source) => _SourceCard(source: source)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              // AI Settings
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF3E7FC),
                            Color(0xFFDEEBFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.secondaryPurple,
                          ),
                        ),
                        title: const Text(
                          'AI Configuration',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Default (${user.aiProvider.provider.toUpperCase()})',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const AIConfigModal(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Debug Settings (only visible in DEBUG_MODE)
              if (AppConstants.debugMode) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Debug Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEV',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFE5E5),
                              Color(0xFFFFCCCC),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bug_report,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text(
                            'View Debug Logs',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'All app logs, errors, and diagnostics',
                            style: TextStyle(fontSize: 13),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DebugLogsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              // Privacy & Sharing
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy & Sharing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingRow(
                      label: 'Anonymous Adds',
                      description: 'Hide your name when adding to shared collections',
                      value: user.settings.anonymousAdds,
                      onChanged: (value) async {
                        try {
                          final authUser = SupabaseConfig.client.auth.currentUser;
                          if (authUser != null) {
                            final supabaseService = ref.read(supabaseServiceProvider);
                            await supabaseService.updateUser(authUser.id, {
                              'settings': {
                                'anonymous_adds': value,
                                'friend_updates': user.settings.friendUpdates,
                              },
                            });
                            ref.invalidate(profileUserProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value 
                                  ? 'Anonymous adds enabled' 
                                  : 'Anonymous adds disabled'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _SettingRow(
                      label: 'Friend Updates',
                      description: 'Get notified when friends save articles',
                      value: user.settings.friendUpdates,
                      onChanged: (value) async {
                        try {
                          final authUser = SupabaseConfig.client.auth.currentUser;
                          if (authUser != null) {
                            final supabaseService = ref.read(supabaseServiceProvider);
                            await supabaseService.updateUser(authUser.id, {
                              'settings': {
                                'anonymous_adds': user.settings.anonymousAdds,
                                'friend_updates': value,
                              },
                            });
                            ref.invalidate(profileUserProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value 
                                  ? 'Friend updates enabled' 
                                  : 'Friend updates disabled'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Account
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          final authUser = SupabaseConfig.client.auth.currentUser;
                          if (authUser == null) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Preparing your data export...'),
                            ),
                          );
                          
                          // TODO: Implement actual data export with share dialog
                          // For now, show success message
                          await Future.delayed(const Duration(seconds: 1));
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data export ready! (Feature coming soon)'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('Export Data'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        foregroundColor: AppTheme.errorRed,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends ConsumerStatefulWidget {
  final source;

  const _SourceCard({required this.source});

  @override
  ConsumerState<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends ConsumerState<_SourceCard> {
  late bool isActive;

  @override
  void initState() {
    super.initState();
    isActive = widget.source.active;
  }

  Future<void> _toggleSource(bool value) async {
    // Check if this is a mock source (simple numeric ID like "1", "2") or real UUID
    final isMockSource = !widget.source.id.contains('-') && widget.source.id.length < 5;
    
    if (isMockSource) {
      // Just update UI for mock sources
      setState(() => isActive = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? '${widget.source.name} enabled (mock mode)' 
              : '${widget.source.name} disabled (mock mode)'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.toggleSource(widget.source.id, value);
      
      // Refresh the sources list and feed - this will rebuild the entire sources section
      ref.invalidate(userSourcesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? '${widget.source.name} enabled' 
              : '${widget.source.name} disabled'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating source: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSource() async {
    // Check if this is a mock source
    final isMockSource = !widget.source.id.contains('-') && widget.source.id.length < 5;
    
    if (isMockSource) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete mock sources'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source'),
        content: Text('Are you sure you want to delete "${widget.source.name}"? This cannot be undone.'),
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
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.deleteSource(widget.source.id);
      
      // Refresh the sources list and feed
      ref.invalidate(userSourcesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Source deleted'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting source: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.source.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.source.topics.map<Widget>((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppTheme.textGray,
            onPressed: _deleteSource,
            tooltip: 'Delete source',
          ),
          Switch(
            value: isActive,
            onChanged: _toggleSource,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

