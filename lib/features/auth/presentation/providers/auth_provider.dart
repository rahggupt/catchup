import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/config/airbridge_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/logger_service.dart';

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
  final LoggerService _logger = LoggerService();
  
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
    _logger.info('Starting user signup process', category: 'Auth');
    
    if (_isMockMode) {
      _logger.warning('Running in mock mode - signup skipped', category: 'Auth');
      return null; // null means success in mock mode
    }
    
    try {
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
        _logger.info('User signed up successfully: ${response.user!.id}', category: 'Auth');
        
        await _createUserProfile(
          uid: response.user!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        );
        
        // Create default collections for new user
        await _createDefaultCollections(response.user!.id);
        
        // Create default RSS sources for new user
        await _createDefaultSources(response.user!.id);
        
        // Track user signup in Airbridge
        await AirbridgeConfig.setUserIdentifier(response.user!.id);
        if (response.user!.email != null) {
          await AirbridgeConfig.setUserEmail(response.user!.email!);
        }
        
        _logger.success('User profile, collections, sources created, and tracked in Airbridge', category: 'Auth');
      }
      
      return response;
    } catch (e, stackTrace) {
      _logger.error('Signup failed', category: 'Auth', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
    
    try {
      _logger.info('Attempting login for: $email', category: 'Auth');
      
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _logger.success('Login successful for: $email', category: 'Auth');
      
      // Ensure user has at least one collection
      if (response.user != null) {
        await _ensureUserHasCollections(response.user!.id);
        
        // Track user login in Airbridge
        await AirbridgeConfig.setUserIdentifier(response.user!.id);
        if (response.user!.email != null) {
          await AirbridgeConfig.setUserEmail(response.user!.email!);
        }
      }
      
      return response;
    } catch (e, stackTrace) {
      _logger.error('Login failed for: $email', category: 'Auth', error: e, stackTrace: stackTrace);
      
      // Parse error message for better user feedback
      final errorMessage = e.toString();
      if (errorMessage.contains('Invalid login credentials')) {
        throw Exception('Invalid email or password. Please check your credentials.');
      } else if (errorMessage.contains('Email not confirmed')) {
        throw Exception('Please confirm your email. Check your inbox for the confirmation link.');
      } else if (errorMessage.contains('Email link is invalid or has expired')) {
        throw Exception('This link has expired. Please request a new one.');
      } else if (errorMessage.contains('User not found')) {
        throw Exception('No account found with this email. Please sign up first.');
      } else {
        throw Exception('Login failed: ${errorMessage}');
      }
    }
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
    
    // Clear Airbridge user data before signing out
    await AirbridgeConfig.clearUser();
    
    await SupabaseConfig.client.auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    _logger.info('Requesting password reset for: $email', category: 'Auth');
    
    if (_isMockMode) {
      _logger.warning('Mock mode - password reset skipped', category: 'Auth');
      return;
    }
    
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      _logger.success('Password reset email sent to: $email', category: 'Auth');
    } catch (e, stackTrace) {
      _logger.error('Password reset failed for: $email', category: 'Auth', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
  
  // Create default collections for new user
  Future<void> _createDefaultCollections(String userId) async {
    final supabaseService = SupabaseService();
    
    _logger.info('Creating three default collections for new user: $userId', category: 'Auth');
    
    final defaultCollections = [
      {'name': 'My Favorites', 'privacy': 'private', 'preview': 'Save your favorite articles here'},
      {'name': 'Reading List', 'privacy': 'private', 'preview': 'Articles you want to read later'},
      {'name': 'Shared Articles', 'privacy': 'invite', 'preview': 'Share articles with friends'},
    ];
    
    for (final collectionData in defaultCollections) {
      try {
        final collection = await supabaseService.createCollection(
          name: collectionData['name']!,
          ownerId: userId,
          privacy: collectionData['privacy']!,
          preview: collectionData['preview'],
        );
        _logger.success('Created default collection: ${collectionData['name']} (ID: ${collection.id})', category: 'Auth');
      } catch (e, stackTrace) {
        _logger.error('Error creating default collection: ${collectionData['name']}', category: 'Auth', error: e, stackTrace: stackTrace);
        // Non-fatal error - user can create collections manually
      }
    }
  }
  
  // Check if user has collections, create default if none exist
  Future<void> _ensureUserHasCollections(String userId) async {
    try {
      _logger.info('Checking if user $userId has collections...', category: 'Auth');
      final supabaseService = SupabaseService();
      final collections = await supabaseService.getUserCollections(userId);
      
      if (collections.isEmpty) {
        _logger.warning('User has no collections, creating three default collections', category: 'Auth');
        await _createDefaultCollections(userId);
      } else {
        _logger.success('User already has ${collections.length} collection(s)', category: 'Auth');
      }
    } catch (e, stackTrace) {
      _logger.error('Error checking user collections', category: 'Auth', error: e, stackTrace: stackTrace);
    }
  }
  
  // Create default RSS sources for new user
  Future<void> _createDefaultSources(String userId) async {
    final supabaseService = SupabaseService();
    
    _logger.info('Creating default RSS sources for new user: $userId', category: 'Auth');
    
    final defaultSources = [
      {
        'name': 'TechCrunch',
        'url': 'https://techcrunch.com/feed/',
        'topics': ['Tech', 'Business', 'Innovation']
      },
      {
        'name': 'Wired',
        'url': 'https://www.wired.com/feed/rss',
        'topics': ['Tech', 'Science', 'AI']
      },
    ];
    
    for (final sourceData in defaultSources) {
      try {
        await supabaseService.createSource(
          userId: userId,
          name: sourceData['name'] as String,
          url: sourceData['url'] as String,
          topics: sourceData['topics'] as List<String>,
        );
        _logger.success('Created default source: ${sourceData['name']}', category: 'Auth');
      } catch (e, stackTrace) {
        _logger.error('Error creating default source: ${sourceData['name']}', category: 'Auth', error: e, stackTrace: stackTrace);
        // Non-fatal error - user can add sources manually
      }
    }
  }
}

