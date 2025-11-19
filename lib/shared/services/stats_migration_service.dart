import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'logger_service.dart';
import '../../core/config/supabase_config.dart';

/// Service to handle one-time migration/recalculation of collection stats
class StatsMigrationService {
  static const String _statsRecalculatedKey = 'stats_recalculated_v1';
  final LoggerService _logger = LoggerService();
  final SupabaseService _supabaseService = SupabaseService();

  /// Check if stats have been recalculated and do it once if needed
  Future<void> ensureStatsRecalculated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRecalculated = prefs.getBool(_statsRecalculatedKey) ?? false;

      if (hasRecalculated) {
        _logger.info('Stats already recalculated, skipping', category: 'Migration');
        return;
      }

      _logger.info('First time after stats fix - recalculating all collection stats', category: 'Migration');

      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser == null) {
        _logger.warning('No authenticated user, skipping stats recalculation', category: 'Migration');
        return;
      }

      // Get all user's collections
      final collections = await _supabaseService.getUserCollections(authUser.id);
      
      _logger.info('Found ${collections.length} collections to recalculate', category: 'Migration');

      // Recalculate stats for each collection
      int successCount = 0;
      for (final collection in collections) {
        try {
          await _supabaseService.recalculateCollectionStats(collection.id);
          successCount++;
          _logger.info('Recalculated stats for collection: ${collection.name}', category: 'Migration');
        } catch (e) {
          _logger.warning('Failed to recalculate stats for collection ${collection.name}: $e', category: 'Migration');
        }
      }

      _logger.success('Stats recalculation complete: $successCount/${collections.length} collections updated', category: 'Migration');

      // Mark as completed
      await prefs.setBool(_statsRecalculatedKey, true);
      _logger.info('Set stats recalculated flag to prevent future runs', category: 'Migration');
    } catch (e, stackTrace) {
      _logger.error('Failed to recalculate stats', category: 'Migration', error: e, stackTrace: stackTrace);
      // Don't rethrow - this shouldn't block app startup
    }
  }

  /// Reset the flag (for testing purposes)
  Future<void> resetFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsRecalculatedKey);
    _logger.info('Reset stats recalculation flag', category: 'Migration');
  }
}

