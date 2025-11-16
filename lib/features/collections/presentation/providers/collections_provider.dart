import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';

// Supabase service provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// User collections provider - includes owned AND member collections
final userCollectionsProvider = FutureProvider<List<CollectionModel>>((ref) async {
  final logger = LoggerService();
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      logger.warning('No authenticated user, returning empty collections', category: 'Collections');
      return [];
    }
    
    logger.info('Fetching all collections for user: ${authUser.id}', category: 'Collections');
    
    // Use the simpler service method instead of complex query
    final supabaseService = SupabaseService();
    final collections = await supabaseService.getUserCollections(authUser.id);
    
    logger.success('Loaded ${collections.length} collections', category: 'Collections');
    
    return collections;
  } catch (e, stackTrace) {
    logger.error('Failed to load collections', category: 'Collections', error: e, stackTrace: stackTrace);
    // Return empty list instead of mock data
    return [];
  }
});

// Realtime collection articles provider for a specific collection
// Listens for INSERT/DELETE events on collection_articles table
final collectionArticlesRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, collectionId) {
    final logger = LoggerService();
    logger.info('Setting up realtime sync for collection: $collectionId', category: 'Collections');
    
    return SupabaseConfig.client
        .from('collection_articles')
        .stream(primaryKey: ['id'])
        .eq('collection_id', collectionId)
        .order('added_at', ascending: false)
        .map((data) {
          logger.info('Realtime update received: ${data.length} articles', category: 'Collections');
          return List<Map<String, dynamic>>.from(data);
        });
  },
);

// Check user permission for a collection
final userCollectionPermissionProvider = FutureProvider.family<String, String>(
  (ref, collectionId) async {
    final logger = LoggerService();
    try {
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser == null) return 'none';
      
      logger.info('Checking permission for collection: $collectionId', category: 'Collections');
      
      final client = SupabaseConfig.client;
      
      // Check if user is owner
      final collectionResponse = await client
          .from('collections')
          .select('owner_id')
          .eq('id', collectionId)
          .maybeSingle();
      
      if (collectionResponse != null && collectionResponse['owner_id'] == authUser.id) {
        logger.success('User is owner of collection', category: 'Collections');
        return 'owner';
      }
      
      // Check if user is member
      final memberResponse = await client
          .from('collection_members')
          .select('role')
          .eq('collection_id', collectionId)
          .eq('user_id', authUser.id)
          .maybeSingle();
      
      if (memberResponse != null) {
        final role = memberResponse['role'] as String;
        logger.success('User is member with role: $role', category: 'Collections');
        return role; // 'editor' or 'viewer'
      }
      
      logger.warning('User has no permission for collection', category: 'Collections');
      return 'none';
    } catch (e, stackTrace) {
      logger.error('Failed to check permission', category: 'Collections', error: e, stackTrace: stackTrace);
      return 'none';
    }
  },
);

