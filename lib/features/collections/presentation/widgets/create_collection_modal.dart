import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../providers/collections_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class CreateCollectionModal extends ConsumerStatefulWidget {
  const CreateCollectionModal({super.key});

  @override
  ConsumerState<CreateCollectionModal> createState() => _CreateCollectionModalState();
}

class _CreateCollectionModalState extends ConsumerState<CreateCollectionModal> {
  final LoggerService _logger = LoggerService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPrivacy = 'private';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create a collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      _logger.info('Creating new collection: ${_nameController.text.trim()}', category: 'Collections');
      
      final supabaseService = SupabaseService();
      
      final description = _descriptionController.text.trim();
      
      await supabaseService.createCollection(
        name: _nameController.text.trim(),
        ownerId: user.id,
        privacy: _selectedPrivacy,
        preview: description.isEmpty ? null : description,
      );
      
      // Refresh collections list and profile stats
      ref.invalidate(userCollectionsProvider);
      ref.invalidate(profileUserProvider);
      
      _logger.success('Collection created successfully', category: 'Collections');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to create collection', category: 'Collections', error: e, stackTrace: stackTrace);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        // Check if it's a unique constraint violation
        final errorMessage = e.toString().contains('23505') || e.toString().toLowerCase().contains('unique')
            ? 'You already have a collection with this name'
            : 'Failed to create collection: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Collection',
                      style: TextStyle(
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
              const SizedBox(height: 24),

              // Collection Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name *',
                  hintText: 'Enter collection name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.collections_bookmark),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a collection name';
                  }
                  return null;
                },
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a description for your collection',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Privacy Settings
              const Text(
                'Privacy *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 8),
              
              // Privacy options
              _buildPrivacyOption(
                'private',
                'Private',
                'Only you can view and edit',
                Icons.lock,
              ),
              const SizedBox(height: 8),
              _buildPrivacyOption(
                'invite',
                'Invite-Only',
                'Only invited members can access',
                Icons.people,
              ),
              const SizedBox(height: 8),
              _buildPrivacyOption(
                'public',
                'Public',
                'Anyone with the link can view',
                Icons.public,
              ),
              
              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createCollection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Collection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedPrivacy == value;
    
    return GestureDetector(
      onTap: _isLoading ? null : () {
        setState(() => _selectedPrivacy = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textGray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.7) : AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

