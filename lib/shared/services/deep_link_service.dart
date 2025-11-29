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
    _logger.info('Initializing deep link listener', category: 'DeepLink');
    
    // Set up Airbridge deep link handler
    Airbridge.setDeeplinkCallback((link) {
      _logger.info('Deep link received: $link', category: 'DeepLink');
      _handleDeepLink(context, ref, link);
    });
  }
  
  /// Handle incoming deep link
  Future<void> _handleDeepLink(BuildContext context, WidgetRef ref, String link) async {
    try {
      _logger.info('Processing deep link: $link', category: 'DeepLink');
      
      final uri = Uri.parse(link);
      final path = uri.path;
      
      // Handle collection share links: https://catchup.airbridge.io/c/{token}
      // or catchup://c/{token}
      if (path.startsWith('/c/')) {
        final token = path.substring(3); // Remove '/c/' prefix
        await _handleCollectionShare(context, ref, token);
      } else {
        _logger.warning('Unknown deep link path: $path', category: 'DeepLink');
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling deep link', category: 'DeepLink', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Handle collection share deep link
  Future<void> _handleCollectionShare(BuildContext context, WidgetRef ref, String token) async {
    try {
      _logger.info('Loading shared collection with token: $token', category: 'DeepLink');
      
      // Fetch collection by shareable token
      final collection = await _supabaseService.getCollectionByToken(token);
      
      if (collection == null) {
        _logger.warning('Collection not found for token: $token', category: 'DeepLink');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shared collection not found or has been removed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      _logger.success('Found collection: ${collection.name}', category: 'DeepLink');
      
      // Navigate to collection details screen
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/collection-details',
          arguments: collection,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading shared collection', category: 'DeepLink', error: e, stackTrace: stackTrace);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load shared collection. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Track collection share event
  static Future<void> trackCollectionShare(String collectionId, String collectionName) async {
    final logger = LoggerService();
    logger.info('Tracking collection share: $collectionName', category: 'DeepLink');
    
    try {
      // Track custom event in Airbridge
      await Airbridge.trackEvent(
        category: 'collection',
        action: 'share',
        label: collectionName,
        semanticAttributes: {
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
  static Future<void> trackCollectionOpen(String collectionId, String collectionName) async {
    final logger = LoggerService();
    logger.info('Tracking collection open: $collectionName', category: 'DeepLink');
    
    try {
      // Track custom event in Airbridge
      await Airbridge.trackEvent(
        category: 'collection',
        action: 'open',
        label: collectionName,
        semanticAttributes: {
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

