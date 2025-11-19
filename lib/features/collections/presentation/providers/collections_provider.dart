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
        .asyncMap((collectionArticles) async {
          logger.info('Realtime update received: ${collectionArticles.length} collection_articles', category: 'Collections');
          
          if (collectionArticles.isEmpty) {
            return [];
          }
          
          // Extract article IDs from collection_articles
          final articleIds = collectionArticles
              .map((ca) => ca['article_id'] as String)
              .toList();
          
          logger.info('Fetching ${articleIds.length} articles from articles table', category: 'Collections');
          
          // Fetch the actual article data
          try {
            final articlesData = await SupabaseConfig.client
                .from('articles')
                .select()
                .inFilter('id', articleIds);
            
            // Create a map of article_id -> article for quick lookup
            final articlesMap = <String, Map<String, dynamic>>{};
            for (final article in articlesData) {
              articlesMap[article['id'] as String] = article as Map<String, dynamic>;
            }
            
            // Combine collection_articles with articles data
            final result = collectionArticles.map((ca) {
              final articleId = ca['article_id'] as String;
              return {
                ...ca,
                'article': articlesMap[articleId],
              };
            }).where((item) => item['article'] != null).toList();
            
            logger.success('Fetched ${result.length} articles with full data', category: 'Collections');
            
            return result;
          } catch (e, stackTrace) {
            logger.error('Failed to fetch articles data', category: 'Collections', error: e, stackTrace: stackTrace);
            return [];
          }
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

