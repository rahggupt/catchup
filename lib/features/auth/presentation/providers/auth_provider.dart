import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  // In mock mode, return an empty stream
  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    return Stream.value(null);
  }
  
  try {
    return SupabaseConfig.auth.onAuthStateChange.map((data) => data.session?.user);
  } catch (e) {
    // If Supabase is not initialized, return empty stream
    return Stream.value(null);
  }
});

// Current user provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  // In mock mode, return null
  if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
    return null;
  }
  
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('uid', user.id)
          .single();
      
      return UserModel.fromJson(response as Map<String, dynamic>);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth service provider
final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  bool get _isMockMode => 
      AppConstants.supabaseUrl.isEmpty || 
      AppConstants.supabaseAnonKey.isEmpty;
  
  // Sign up with email and password
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    if (_isMockMode) {
      // Mock signup - just return success
      return null; // null means success in mock mode
    }
    
    final response = await SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      },
    );
    
    // Create user profile
    if (response.user != null) {
      await _createUserProfile(
        uid: response.user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
    }
    
    return response;
  }
  
  // Sign in with email and password
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isMockMode) {
      // Mock login - just return success
      return null; // null means success in mock mode
    }
    
    return await SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_isMockMode) {
      // Mock Google login
      return true;
    }
    
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.catchup.mindmap://callback',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    if (_isMockMode) {
      // Mock logout - do nothing
      return;
    }
    
    await SupabaseConfig.client.auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    if (_isMockMode) {
      // Mock password reset
      return;
    }
    
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }
  
  // Create user profile in database
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await SupabaseConfig.client.from('users').insert({
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'stats': {
        'articles': 0,
        'collections': 0,
        'chats': 0,
      },
      'settings': {
        'anonymous_adds': false,
        'friend_updates': true,
      },
      'ai_provider': {
        'provider': 'gemini',
        'api_key': null,
      },
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

