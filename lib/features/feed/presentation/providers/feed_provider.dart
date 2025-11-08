import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../../../../shared/services/supabase_service.dart';

// Supabase service provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// Feed articles provider
final feedArticlesProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<ArticleModel>>>((ref) {
  return FeedNotifier(ref.read(supabaseServiceProvider));
});

class FeedNotifier extends StateNotifier<AsyncValue<List<ArticleModel>>> {
  final SupabaseService _supabaseService;
  
  FeedNotifier(this._supabaseService) : super(const AsyncValue.loading()) {
    loadArticles();
  }

  bool get _isMockMode => 
      AppConstants.supabaseUrl.isEmpty || 
      AppConstants.supabaseAnonKey.isEmpty;

  Future<void> loadArticles() async {
    state = const AsyncValue.loading();
    try {
      List<ArticleModel> articles;
      
      if (_isMockMode) {
        // Use mock data if no Supabase credentials
        await Future.delayed(const Duration(seconds: 1));
        articles = MockDataService.getMockArticles();
      } else {
        // Load real articles from Supabase
        articles = await _supabaseService.getArticles(limit: 20);
        
        // If no articles exist, seed with mock data
        if (articles.isEmpty) {
          print('No articles found in database. Using mock data for demo.');
          articles = MockDataService.getMockArticles();
        }
      }
      
      state = AsyncValue.data(articles);
    } catch (e, stack) {
      print('Error loading articles: $e');
      // Fallback to mock data on error
      final articles = MockDataService.getMockArticles();
      state = AsyncValue.data(articles);
    }
  }

  Future<void> refresh() async {
    await loadArticles();
  }

  void removeArticle(String articleId) {
    state.whenData((articles) {
      final updatedArticles = articles.where((a) => a.id != articleId).toList();
      state = AsyncValue.data(updatedArticles);
    });
  }
}

// Selected filter provider
final selectedFilterProvider = StateProvider<String>((ref) => 'All Sources');

// Available filters
final filtersProvider = Provider<List<String>>((ref) {
  return ['All Sources', 'AI Topics', 'Friends\' Adds', 'Tech', 'Science'];
});

// Current article index provider
final currentArticleIndexProvider = StateProvider<int>((ref) => 0);

// Liked articles provider
final likedArticlesProvider = StateNotifierProvider<LikedArticlesNotifier, Set<String>>((ref) {
  return LikedArticlesNotifier();
});

class LikedArticlesNotifier extends StateNotifier<Set<String>> {
  LikedArticlesNotifier() : super({});

  void toggleLike(String articleId) {
    final newState = Set<String>.from(state);
    if (newState.contains(articleId)) {
      newState.remove(articleId);
    } else {
      newState.add(articleId);
    }
    state = newState;
  }

  bool isLiked(String articleId) {
    return state.contains(articleId);
  }
}

