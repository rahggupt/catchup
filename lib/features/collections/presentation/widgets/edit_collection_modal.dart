import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';
import '../providers/collections_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class EditCollectionModal extends ConsumerStatefulWidget {
  final CollectionModel collection;

  const EditCollectionModal({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<EditCollectionModal> createState() => _EditCollectionModalState();
}

class _EditCollectionModalState extends ConsumerState<EditCollectionModal> {
  final LoggerService _logger = LoggerService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageController;
  late String _selectedPrivacy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(text: widget.collection.preview ?? '');
    _coverImageController = TextEditingController(text: widget.collection.coverImage ?? '');
    _selectedPrivacy = widget.collection.privacy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      _logger.info('Updating collection: ${widget.collection.name}', category: 'Collections');
      
      final supabaseService = SupabaseService();
      
      // Build update data
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'privacy': _selectedPrivacy,
      };
      
      // Add optional fields if changed
      final description = _descriptionController.text.trim();
      if (description.isNotEmpty) {
        updateData['preview'] = description;
      } else {
        updateData['preview'] = null;
      }
      
      final coverImage = _coverImageController.text.trim();
      if (coverImage.isNotEmpty) {
        updateData['cover_image'] = coverImage;
      } else {
        updateData['cover_image'] = null;
      }
      
      // Update collection
      await supabaseService.updateCollection(widget.collection.id, updateData);
      
      // Refresh collections
      ref.invalidate(userCollectionsProvider);
      ref.invalidate(profileUserProvider);
      
      _logger.success('Collection updated successfully', category: 'Collections');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to update collection', category: 'Collections', error: e, stackTrace: stackTrace);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
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
                  const Icon(Icons.edit, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Collection',
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

              // Cover Image URL
              TextFormField(
                controller: _coverImageController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL (Optional)',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
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

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
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
                        'Save Changes',
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

