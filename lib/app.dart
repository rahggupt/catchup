import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/collections/presentation/screens/collection_details_screen.dart';
import 'shared/widgets/main_navigation.dart';
import 'shared/models/collection_model.dart';

class MindmapAggregatorApp extends ConsumerWidget {
  const MindmapAggregatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainNavigation(),
      },
      onGenerateRoute: (settings) {
        // Handle collection-details route with arguments
        if (settings.name == '/collection-details') {
          final collection = settings.arguments as CollectionModel;
          return MaterialPageRoute(
            builder: (context) => CollectionDetailsScreen(collection: collection),
          );
        }
        return null;
      },
    );
  }
}

