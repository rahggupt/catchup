import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/source_model.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/services/supabase_service.dart';

// Supabase service provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// Current logged-in user provider
final profileUserProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  // Check if in mock mode
  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    return MockDataService.getMockUser();
  }
  
  try {
    // Get current auth user
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      // Not logged in, return mock user
      return MockDataService.getMockUser();
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
    return MockDataService.getMockUser();
  }
});

// Helper function to get real stats from database
Future<Map<String, int>> _getRealStats(SupabaseService service, String userId) async {
  try {
    final client = SupabaseConfig.client;
    
    // Count collections
    final collectionsResponse = await client
        .from('collections')
        .select('id')
        .eq('owner_id', userId);
    final collectionsCount = (collectionsResponse as List).length;
    
    // Count articles in user's collections
    final articlesResponse = await client
        .from('collection_articles')
        .select('id')
        .inFilter('collection_id', collectionsResponse.map((c) => c['id']).toList());
    final articlesCount = (articlesResponse as List).length;
    
    // Chats count (if you have a chats table)
    int chatsCount = 0;
    try {
      final chatsResponse = await client
          .from('chats')
          .select('id')
          .eq('user_id', userId);
      chatsCount = (chatsResponse as List).length;
    } catch (e) {
      // Chats table might not exist
      print('Chats table not found: $e');
    }
    
    print('Real stats: collections=$collectionsCount, articles=$articlesCount, chats=$chatsCount');
    
    return {
      'collections': collectionsCount,
      'articles': articlesCount,
      'chats': chatsCount,
    };
  } catch (e) {
    print('Error getting real stats: $e');
    return {'collections': 0, 'articles': 0, 'chats': 0};
  }
}

// User sources provider
final userSourcesProvider = FutureProvider.autoDispose<List<SourceModel>>((ref) async {
  // Check if in mock mode
  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    return MockDataService.getMockSources();
  }
  
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      return MockDataService.getMockSources();
    }
    
    final supabaseService = ref.read(supabaseServiceProvider);
    final sources = await supabaseService.getUserSources(authUser.id);
    
    // If no sources, return mock sources for demo
    if (sources.isEmpty) {
      return MockDataService.getMockSources();
    }
    
    return sources;
  } catch (e) {
    print('Error loading sources: $e');
    return MockDataService.getMockSources();
  }
});

