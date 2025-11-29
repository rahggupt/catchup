import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';
import 'supabase_service.dart';

class DeepLinkService {
  final LoggerService _logger = LoggerService();
  final SupabaseService _supabaseService = SupabaseService();
  
  /// Initialize deep link listener
  void initialize(BuildContext context, WidgetRef ref) {
    _logger.info('🚀 [DeepLink] Initializing deep link listener', category: 'DeepLink');
    _logger.info('📱 [DeepLink] Airbridge SDK ready to receive links', category: 'DeepLink');
    
    // Set up Airbridge deep link handler
    Airbridge.setOnDeeplinkReceived((link) {
      _logger.info('📬 [DeepLink] ========== DEEP LINK RECEIVED ==========', category: 'DeepLink');
      _logger.info('🔗 [DeepLink] Full URL: $link', category: 'DeepLink');
      _handleDeepLink(context, ref, link);
    });
    
    _logger.success('✅ [DeepLink] Deep link handler registered successfully', category: 'DeepLink');
  }
  
  /// Handle incoming deep link
  Future<void> _handleDeepLink(BuildContext context, WidgetRef ref, String link) async {
    try {
      _logger.info('🔄 [DeepLink] Processing deep link: $link', category: 'DeepLink');
      
      final uri = Uri.parse(link);
      _logger.info('🌐 [DeepLink] Parsed URI:', category: 'DeepLink');
      _logger.info('   - Scheme: ${uri.scheme}', category: 'DeepLink');
      _logger.info('   - Host: ${uri.host}', category: 'DeepLink');
      _logger.info('   - Path: ${uri.path}', category: 'DeepLink');
      
      final path = uri.path;
      
      // Handle collection share links: https://catchup.airbridge.io/c/{token}
      // or catchup://c/{token}
      if (path.startsWith('/c/')) {
        final token = path.substring(3); // Remove '/c/' prefix
        _logger.info('🎯 [DeepLink] Extracted token: "$token"', category: 'DeepLink');
        await _handleCollectionShare(context, ref, token);
      } else {
        _logger.warning('⚠️ [DeepLink] Unknown deep link path: $path', category: 'DeepLink');
        _logger.warning('   Expected format: /c/{token}', category: 'DeepLink');
      }
    } catch (e, stackTrace) {
      _logger.error('💥 [DeepLink] Error handling deep link', category: 'DeepLink', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Handle collection share deep link
  Future<void> _handleCollectionShare(BuildContext context, WidgetRef ref, String token) async {
    try {
      _logger.info('📂 [DeepLink] ========== LOADING COLLECTION ==========', category: 'DeepLink');
      _logger.info('🔑 [DeepLink] Token: "$token"', category: 'DeepLink');
      _logger.info('🔑 [DeepLink] Token length: ${token.length} characters', category: 'DeepLink');
      
      // Fetch collection by shareable token
      _logger.info('⏳ [DeepLink] Calling getCollectionByToken...', category: 'DeepLink');
      final collection = await _supabaseService.getCollectionByToken(token);
      
      if (collection == null) {
        _logger.warning('❌ [DeepLink] Collection not found for token: "$token"', category: 'DeepLink');
        _logger.warning('', category: 'DeepLink');
        _logger.warning('🔍 [DeepLink] Troubleshooting steps:', category: 'DeepLink');
        _logger.warning('   1. Check if token exists in database: SELECT * FROM collections WHERE shareable_token = \'$token\'', category: 'DeepLink');
        _logger.warning('   2. Check if share_enabled = true', category: 'DeepLink');
        _logger.warning('   3. Check RLS policy: CREATE POLICY "Anyone can view shared collections" ON collections FOR SELECT USING (share_enabled = true)', category: 'DeepLink');
        _logger.warning('   4. Try disabling RLS temporarily: ALTER TABLE collections DISABLE ROW LEVEL SECURITY', category: 'DeepLink');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection not found: "$token"\n\nCheck debug logs for details.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      _logger.success('✅ [DeepLink] Collection found!', category: 'DeepLink');
      _logger.success('   - Name: ${collection.name}', category: 'DeepLink');
      _logger.success('   - ID: ${collection.id}', category: 'DeepLink');
      _logger.success('   - Articles: ${collection.stats.articleCount}', category: 'DeepLink');
      
      // Track collection open event
      trackCollectionOpen(collection.id, collection.name);
      
      // Navigate to collection details screen
      _logger.info('🧭 [DeepLink] Navigating to collection details...', category: 'DeepLink');
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/collection-details',
          arguments: collection,
        );
        _logger.success('✅ [DeepLink] Navigation successful!', category: 'DeepLink');
      } else {
        _logger.warning('⚠️ [DeepLink] Context not mounted, cannot navigate', category: 'DeepLink');
      }
    } catch (e, stackTrace) {
      _logger.error('💥 [DeepLink] Error loading shared collection', category: 'DeepLink', error: e, stackTrace: stackTrace);
      _logger.error('   Error type: ${e.runtimeType}', category: 'DeepLink');
      _logger.error('   Error message: $e', category: 'DeepLink');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e\n\nCheck debug logs for details.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  /// Track collection share event
  static void trackCollectionShare(String collectionId, String collectionName) {
    final logger = LoggerService();
    logger.info('Tracking collection share: $collectionName', category: 'DeepLink');
    
    try {
      // Track custom event in Airbridge
      Airbridge.trackEvent(
        category: 'collection_share',
        customAttributes: {
          'collection_id': collectionId,
          'collection_name': collectionName,
        },
      );
      
      logger.success('Collection share tracked', category: 'DeepLink');
    } catch (e, stackTrace) {
      logger.error('Failed to track share event', category: 'DeepLink', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Track collection open event
  static void trackCollectionOpen(String collectionId, String collectionName) {
    final logger = LoggerService();
    logger.info('Tracking collection open: $collectionName', category: 'DeepLink');
    
    try {
      // Track custom event in Airbridge
      Airbridge.trackEvent(
        category: 'collection_open',
        customAttributes: {
          'collection_id': collectionId,
          'collection_name': collectionName,
        },
      );
      
      logger.success('Collection open tracked', category: 'DeepLink');
    } catch (e, stackTrace) {
      logger.error('Failed to track open event', category: 'DeepLink', error: e, stackTrace: stackTrace);
    }
  }
}

/// Provider for DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

