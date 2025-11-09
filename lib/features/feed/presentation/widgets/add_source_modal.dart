import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/rss_feed_provider.dart';

class AddSourceModal extends ConsumerStatefulWidget {
  const AddSourceModal({super.key});

  @override
  ConsumerState<AddSourceModal> createState() => _AddSourceModalState();
}

class _AddSourceModalState extends ConsumerState<AddSourceModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final List<String> _selectedTopics = [];
  bool _isLoading = false;

  final List<String> _availableTopics = [
    'Tech',
    'Science',
    'Politics',
    'Business',
    'Health',
    'Climate',
    'AI',
    'Innovation',
  ];

  final List<Map<String, String>> _suggestedSources = [
    {'name': 'Wired', 'url': 'wired.com'},
    {'name': 'MIT Tech Review', 'url': 'technologyreview.com'},
    {'name': 'BBC News', 'url': 'bbc.com/news'},
    {'name': 'The Verge', 'url': 'theverge.com'},
    {'name': 'TechCrunch', 'url': 'techcrunch.com'},
    {'name': 'Ars Technica', 'url': 'arstechnica.com'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Check if Supabase is initialized
        final isSupabaseInitialized = AppConstants.supabaseUrl.isNotEmpty && 
                                       AppConstants.supabaseAnonKey.isNotEmpty;
        
        if (!isSupabaseInitialized) {
          // Mock mode - just show success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Source "${_nameController.text}" added! (Mock Mode - Configure Supabase for real data)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.pop(context);
          }
          return;
        }

        final user = SupabaseConfig.client.auth.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        final supabaseService = SupabaseService();
        await supabaseService.createSource(
          userId: user.id,
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          topics: _selectedTopics,
        );

        // Refresh the sources list and feed
        ref.invalidate(userSourcesProvider);
        // Force refresh the feed to show articles from new source
        ref.invalidate(feedArticlesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Source "${_nameController.text}" added! Refreshing feed...'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        // Log technical error for debugging
        print('❌ Error adding source: $e');
        
        if (mounted) {
          // Show user-friendly error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to add source. Please try again.'),
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
  }

  void _selectSuggestedSource(Map<String, String> source) {
    _nameController.text = source['name']!;
    _urlController.text = source['url']!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  'Add Source',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Suggested Sources
                    const Text(
                      'Suggested Sources',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedSources.map((source) {
                        return ActionChip(
                          label: Text(
                            source['name']!,
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => _selectSuggestedSource(source),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderGray),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Custom Source
                    const Text(
                      'Or Add Custom Source',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Source Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Source Name',
                        hintText: 'e.g., Wired',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a source name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Source URL
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Website URL or RSS Feed',
                        hintText: 'e.g., wired.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Topics
                    const Text(
                      'Filter by Topics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTopics.map((topic) {
                        final isSelected = _selectedTopics.contains(topic);
                        return FilterChip(
                          label: Text(topic),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTopics.add(topic);
                              } else {
                                _selectedTopics.remove(topic);
                              }
                            });
                          },
                          backgroundColor: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.backgroundLight,
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textGray,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderGray)),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Source'),
            ),
          ),
        ],
      ),
    );
  }
}

