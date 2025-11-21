import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static Future<void> initialize() async {
    // Skip Supabase initialization if credentials are not configured
    if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
      print('Supabase credentials not configured. Running in mock mode.');
      return;
    }
    
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Session persists by default in supabase_flutter 2.5+
        autoRefreshToken: true,
      ),
    );
  }
  
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase not initialized. Please run SupabaseConfig.initialize() first or configure credentials.');
    }
  }
  
  static GoTrueClient get auth {
    try {
      return client.auth;
    } catch (e) {
      throw Exception('Supabase not initialized. Running in mock mode.');
    }
  }
  
  static SupabaseStorageClient get storage {
    try {
      return client.storage;
    } catch (e) {
      throw Exception('Supabase not initialized. Running in mock mode.');
    }
  }
}

