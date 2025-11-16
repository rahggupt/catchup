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
    
    logger.info('Fetching all collections for user (owned + member)', category: 'Collections');
    
    final client = SupabaseConfig.client;
    
    // Fetch collections where user is owner OR member
    // Using a left join with collection_members to get all collections user has access to
    final response = await client
        .from('collections')
        .select('*, collection_members!left(user_id, role)')
        .or('owner_id.eq.${authUser.id},collection_members.user_id.eq.${authUser.id}')
        .order('created_at', ascending: false);
    
    final collections = (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();
    
    // Remove duplicates (in case user appears in both owner and members)
    final uniqueCollections = <String, CollectionModel>{};
    for (final collection in collections) {
      uniqueCollections[collection.id] = collection;
    }
    
    final result = uniqueCollections.values.toList();
    logger.success('Loaded ${result.length} collections (owned + member)', category: 'Collections');
    
    return result;
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

