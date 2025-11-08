import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/supabase_service.dart';
import '../providers/profile_provider.dart';

class AIConfigModal extends ConsumerStatefulWidget {
  const AIConfigModal({super.key});

  @override
  ConsumerState<AIConfigModal> createState() => _AIConfigModalState();
}

class _AIConfigModalState extends ConsumerState<AIConfigModal> {
  String _selectedProvider = 'gemini';
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'description': 'Fast, accurate, free tier available',
      'icon': Icons.psychology,
      'color': Color(0xFF4285F4),
    },
    {
      'id': 'openai',
      'name': 'OpenAI GPT-4',
      'description': 'Most advanced, requires API key',
      'icon': Icons.smart_toy,
      'color': Color(0xFF10A37F),
    },
    {
      'id': 'claude',
      'name': 'Anthropic Claude',
      'description': 'Long context, helpful responses',
      'icon': Icons.chat_bubble,
      'color': Color(0xFFD97757),
    },
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final supabaseService = SupabaseService();
      await supabaseService.updateUser(user.id, {
        'ai_provider': {
          'provider': _selectedProvider,
          'api_key': _apiKeyController.text.isNotEmpty 
              ? _apiKeyController.text.trim() 
              : null,
        },
      });

      // Refresh user profile
      ref.invalidate(profileUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI configuration saved!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.secondaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Configuration',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your AI Provider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select which AI model to use for article summaries and chat.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Provider Options
                  ..._providers.map((provider) {
                    final isSelected = _selectedProvider == provider['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedProvider = provider['id']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? provider['color'].withOpacity(0.1)
                              : AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? provider['color']
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: provider['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                provider['icon'],
                                color: provider['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider['description'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: provider['color'],
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // API Key (Optional)
                  if (_selectedProvider != 'gemini') ...[
                    const Text(
                      'API Key (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your API key',
                        prefixIcon: Icon(Icons.key),
                        helperText: 'Leave empty to use app default',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About AI Providers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Google Gemini is free and works great for most users. Other providers require API keys but may offer different capabilities.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderGray)),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }
}

