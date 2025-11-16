import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../../shared/services/stats_migration_service.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final LoggerService _logger = LoggerService();
  final StatsMigrationService _statsMigration = StatsMigrationService();
  
  @override
  void initState() {
    super.initState();
    _logger.info('App starting - Splash screen loaded', category: 'App');
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _logger.info('Checking authentication status', category: 'Auth');
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // In mock mode (no Supabase credentials), skip to login
    if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
      _logger.warning('No Supabase credentials configured - running in mock mode', category: 'Auth');
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    
    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (user) async {
        if (user != null) {
          _logger.success('User authenticated - running migrations', category: 'Auth');
          
          // Run one-time stats recalculation in the background
          _statsMigration.ensureStatsRecalculated();
          
          _logger.info('Navigating to home', category: 'Auth');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          _logger.info('No authenticated user - navigating to login', category: 'Auth');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      loading: () {
        _logger.warning('Auth state still loading after timeout - navigating to login', category: 'Auth');
        Navigator.of(context).pushReplacementNamed('/login');
      },
      error: (error, stackTrace) {
        _logger.error('Auth check failed - navigating to login', category: 'Auth', error: error, stackTrace: stackTrace);
        Navigator.of(context).pushReplacementNamed('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon/Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Personal Knowledge Hub',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

