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
  // Check if in mock mode
  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    return MockDataService.getMockCollections();
  }
  
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    
    if (authUser == null) {
      return MockDataService.getMockCollections();
    }
    
    final supabaseService = ref.read(supabaseServiceProvider);
    final collections = await supabaseService.getUserCollections(authUser.id);
    
    // Return real collections (including default ones created on signup)
    return collections;
  } catch (e) {
    print('Error loading collections: $e');
    return MockDataService.getMockCollections();
  }
});

