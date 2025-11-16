import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/collection_model.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/services/supabase_service.dart';

// Supabase service provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// User collections provider
final userCollectionsProvider = FutureProvider<List<CollectionModel>>((ref) async {
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      print('No authenticated user, returning empty collections');
      return [];
    }
    
    final supabaseService = ref.read(supabaseServiceProvider);
    final collections = await supabaseService.getUserCollections(authUser.id);
    
    print('Loaded ${collections.length} collections for user');
    return collections;
  } catch (e) {
    print('Error loading collections: $e');
    // Return empty list instead of mock data
    return [];
  }
});

