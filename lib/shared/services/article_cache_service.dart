import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

/// Service for caching articles locally
class ArticleCacheService {
  static const String _cacheKey = 'cached_articles';
  static const String _timestampKey = 'cache_timestamp';
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Save articles to cache
  Future<void> cacheArticles(List<ArticleModel> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert articles to JSON
      final jsonList = articles.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Save to cache
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('Cached ${articles.length} articles');
    } catch (e) {
      print('Error caching articles: $e');
    }
  }

  /// Get cached articles
  Future<List<ArticleModel>?> getCachedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) {
        print('No cached articles found');
        return null;
      }

      // Parse articles
      final jsonList = jsonDecode(jsonString) as List;
      final articles = jsonList.map((json) => ArticleModel.fromJson(json)).toList();
      
      print('Loaded ${articles.length} articles from cache');
      return articles;
    } catch (e) {
      print('Error loading cached articles: $e');
      return null;
    }
  }

  /// Check if cache is fresh (less than 5 minutes old)
  Future<bool> isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);
      
      final isFresh = age < _cacheValidDuration;
      print('Cache age: ${age.inMinutes} minutes, fresh: $isFresh');
      return isFresh;
    } catch (e) {
      print('Error checking cache freshness: $e');
      return false;
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);
      
      return age.inMinutes;
    } catch (e) {
      print('Error getting cache age: $e');
      return null;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      print('Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}

