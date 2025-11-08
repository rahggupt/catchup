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
final profileUserProvider = FutureProvider<UserModel>((ref) async {
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
    final user = await supabaseService.getUser(authUser.id);
    
    if (user != null) {
      return user;
    }
    
    // If user profile doesn't exist, create it
    return await supabaseService.createUser(
      uid: authUser.id,
      email: authUser.email!,
      firstName: authUser.userMetadata?['first_name'] ?? 'User',
      lastName: authUser.userMetadata?['last_name'] ?? 'Name',
      phoneNumber: authUser.userMetadata?['phone_number'],
    );
  } catch (e) {
    print('Error loading user profile: $e');
    return MockDataService.getMockUser();
  }
});

// User sources provider
final userSourcesProvider = FutureProvider<List<SourceModel>>((ref) async {
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

