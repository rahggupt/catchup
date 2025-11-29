import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'core/config/airbridge_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file (for local development)
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Loaded .env file successfully');
  } catch (e) {
    print('⚠️  Could not load .env file: $e');
    print('   Running with compile-time environment variables');
  }
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize Airbridge for deep linking and analytics
  await AirbridgeConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MindmapAggregatorApp(),
    ),
  );
}

