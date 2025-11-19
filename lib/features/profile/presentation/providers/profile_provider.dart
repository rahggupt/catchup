import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/source_model.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';

// Supabase service provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// Current logged-in user provider
final profileUserProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  try {
    // Get current auth user
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      throw Exception('User not logged in');
    }
    
    // Get user profile from database
    final supabaseService = ref.read(supabaseServiceProvider);
    var user = await supabaseService.getUser(authUser.id);
    
    if (user == null) {
      // If user profile doesn't exist, create it
      user = await supabaseService.createUser(
        uid: authUser.id,
        email: authUser.email!,
        firstName: authUser.userMetadata?['first_name'] ?? authUser.email!.split('@')[0],
        lastName: authUser.userMetadata?['last_name'] ?? '',
        phoneNumber: authUser.userMetadata?['phone_number'],
      );
    }
    
    // Get REAL stats from database
    final stats = await _getRealStats(supabaseService, authUser.id);
    
    // Update user with real stats
    return user.copyWith(
      stats: UserStats(
        collections: stats['collections'] ?? 0,
        articles: stats['articles'] ?? 0,
        chats: stats['chats'] ?? 0,
      ),
    );
  } catch (e) {
    print('Error loading user profile: $e');
    rethrow; // Let error bubble up to UI
  }
});

// Helper function to get real stats from database
Future<Map<String, int>> _getRealStats(SupabaseService service, String userId) async {
  final logger = LoggerService();
  try {
    logger.info('Calculating profile stats for user: $userId', category: 'Profile');
    final client = SupabaseConfig.client;
    
    // Count collections owned by the user
    final collectionsResponse = await client
        .from('collections')
        .select('id')
        .eq('owner_id', userId);
    final collectionsCount = (collectionsResponse as List).length;
    logger.info('Found $collectionsCount collections owned by user', category: 'Profile');
    
    // Count articles in user's collections
    int articlesCount = 0;
    if (collectionsCount > 0) {
      final collectionIds = collectionsResponse.map((c) => c['id']).toList();
      try {
        final articlesResponse = await client
            .from('collection_articles')
            .select('article_id')
            .inFilter('collection_id', collectionIds);
        
        // Count unique article IDs
        final uniqueArticleIds = <String>{};
        for (final item in (articlesResponse as List)) {
          if (item['article_id'] != null) {
            uniqueArticleIds.add(item['article_id'].toString());
          }
        }
        articlesCount = uniqueArticleIds.length;
        logger.info('Found $articlesCount unique articles across collections', category: 'Profile');
      } catch (e, stackTrace) {
        logger.error('Failed to count articles', category: 'Profile', error: e, stackTrace: stackTrace);
      }
    }
    
    // Count chats created by the user
    int chatsCount = 0;
    try {
      final chatsResponse = await client
          .from('chats')
          .select('id')
          .eq('user_id', userId);
      chatsCount = (chatsResponse as List).length;
      logger.info('Found $chatsCount chats created by user', category: 'Profile');
    } catch (e) {
      logger.warning('Chats table not found or empty', category: 'Profile');
    }
    
    logger.success('Profile stats verified: collections=$collectionsCount, articles=$articlesCount, chats=$chatsCount', category: 'Profile');
    
    return {
      'collections': collectionsCount,
      'articles': articlesCount,
      'chats': chatsCount,
    };
  } catch (e, stackTrace) {
    logger.error('Failed to calculate profile stats', category: 'Profile', error: e, stackTrace: stackTrace);
    return {'collections': 0, 'articles': 0, 'chats': 0};
  }
}

// User sources provider
final userSourcesProvider = FutureProvider.autoDispose<List<SourceModel>>((ref) async {
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      print('No authenticated user, returning empty sources');
      return [];
    }
    
    final supabaseService = ref.read(supabaseServiceProvider);
    final sources = await supabaseService.getUserSources(authUser.id);
    
    // Remove duplicates by URL (client-side backup)
    final uniqueSources = <String, SourceModel>{};
    for (final source in sources) {
      uniqueSources[source.url] = source; // Overwrites duplicates, keeping the last one
    }
    final dedupedSources = uniqueSources.values.toList();
    
    if (dedupedSources.length != sources.length) {
      print('⚠️  Removed ${sources.length - dedupedSources.length} duplicate sources');
    }
    
    print('Loaded ${dedupedSources.length} sources from database');
    return dedupedSources;
  } catch (e) {
    print('Error loading sources: $e');
    // Return empty list instead of mock data
    return [];
  }
});

// User AI configuration provider
final userAIConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final logger = LoggerService();
  try {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      logger.info('No authenticated user, returning default AI config', category: 'Profile');
      return {'provider': 'gemini', 'api_key': null};
    }
    
    logger.info('Fetching AI config for user: ${user.id}', category: 'Profile');
    final supabaseService = SupabaseService();
    final userData = await supabaseService.getUser(user.id);
    
    if (userData == null) {
      logger.warning('User data not found, returning default AI config', category: 'Profile');
      return {'provider': 'gemini', 'api_key': null};
    }
    
    // Access aiProvider directly from UserModel
    final aiProviderConfig = userData.aiProvider;
    
    logger.success('AI config loaded: provider=${aiProviderConfig.provider}', category: 'Profile');
    return {
      'provider': aiProviderConfig.provider,
      'api_key': aiProviderConfig.apiKey,
    };
  } catch (e, stackTrace) {
    logger.error('Failed to fetch AI config', category: 'Profile', error: e, stackTrace: stackTrace);
    return {'provider': 'gemini', 'api_key': null};
  }
});

