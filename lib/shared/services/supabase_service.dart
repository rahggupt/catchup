import '../../core/config/supabase_config.dart';
import '../models/article_model.dart';
import '../models/collection_model.dart';
import '../models/source_model.dart';
import '../models/user_model.dart';

/// Service for Supabase database operations
class SupabaseService {
  final _client = SupabaseConfig.client;

  // ===== Articles =====
  
  Future<List<ArticleModel>> getArticles({int limit = 20}) async {
    final response = await _client
        .from('articles')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    
    return (response as List)
        .map((json) => ArticleModel.fromJson(json))
        .toList();
  }

  Future<ArticleModel> createArticle(ArticleModel article) async {
    final response = await _client
        .from('articles')
        .insert(article.toJson())
        .select()
        .single();
    
    return ArticleModel.fromJson(response);
  }

  // ===== Collections =====
  
  Future<List<CollectionModel>> getUserCollections(String userId) async {
    final response = await _client
        .from('collections')
        .select()
        .or('owner_id.eq.$userId,collaborator_ids.cs.{$userId}')
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();
  }

  Future<CollectionModel> createCollection({
    required String name,
    required String ownerId,
    required String privacy,
    String? preview,
  }) async {
    final response = await _client
        .from('collections')
        .insert({
          'name': name,
          'owner_id': ownerId,
          'privacy': privacy,
          'preview': preview,
        })
        .select()
        .single();
    
    // Update user stats - increment collections count
    await _incrementUserStat(ownerId, 'collections');
    
    return CollectionModel.fromJson(response);
  }

  Future<void> deleteCollection(String collectionId) async {
    // Delete collection articles first (foreign key constraint)
    await _client
        .from('collection_articles')
        .delete()
        .eq('collection_id', collectionId);
    
    // Delete the collection
    await _client
        .from('collections')
        .delete()
        .eq('id', collectionId);
  }

  // Helper method to increment user stats
  Future<void> _incrementUserStat(String userId, String statName) async {
    try {
      // Get current stats
      final userResponse = await _client
          .from('users')
          .select('stats')
          .eq('uid', userId)
          .single();
      
      final stats = userResponse['stats'] as Map<String, dynamic>? ?? {
        'articles': 0,
        'collections': 0,
        'chats': 0,
      };
      
      // Increment the specified stat
      stats[statName] = (stats[statName] as int? ?? 0) + 1;
      
      // Update the stats
      await _client
          .from('users')
          .update({'stats': stats})
          .eq('uid', userId);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // ===== Sources =====
  
  Future<List<SourceModel>> getUserSources(String userId) async {
    final response = await _client
        .from('sources')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);
    
    return (response as List)
        .map((json) => SourceModel.fromJson(json))
        .toList();
  }

  Future<SourceModel> createSource({
    required String userId,
    required String name,
    required String url,
    required List<String> topics,
  }) async {
    final response = await _client
        .from('sources')
        .insert({
          'user_id': userId,
          'name': name,
          'url': url,
          'topics': topics,
        })
        .select()
        .single();
    
    return SourceModel.fromJson(response);
  }

  Future<void> toggleSource(String sourceId, bool active) async {
    await _client
        .from('sources')
        .update({'active': active})
        .eq('id', sourceId);
  }

  // ===== Users =====
  
  Future<UserModel?> getUser(String uid) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('uid', uid)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> createUser({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? bio,
  }) async {
    final response = await _client
        .from('users')
        .insert({
          'uid': uid,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'bio': bio,
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
        })
        .select()
        .single();
    
    return UserModel.fromJson(response);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _client
        .from('users')
        .update(updates)
        .eq('uid', uid);
  }

  // ===== Collection Articles =====
  
  Future<void> addArticleToCollection({
    required String collectionId,
    required String articleId,
    required String addedBy,
  }) async {
    await _client.from('collection_articles').insert({
      'collection_id': collectionId,
      'article_id': articleId,
      'added_by': addedBy,
    });
    
    // Update user stats - increment articles count
    await _incrementUserStat(addedBy, 'articles');
  }

  Future<List<ArticleModel>> getCollectionArticles(String collectionId) async {
    final response = await _client
        .from('collection_articles')
        .select('article_id, articles(*)')
        .eq('collection_id', collectionId);
    
    return (response as List)
        .map((item) => ArticleModel.fromJson(item['articles']))
        .toList();
  }

  // ===== Chats & Messages =====
  
  Future<void> createChat({
    required String userId,
    String? collectionId,
    String? title,
  }) async {
    await _client.from('chats').insert({
      'user_id': userId,
      'collection_id': collectionId,
      'title': title,
    });
  }

  Future<void> saveMessage({
    required String chatId,
    required String role,
    required String content,
    List<Map<String, dynamic>>? citations,
  }) async {
    await _client.from('messages').insert({
      'chat_id': chatId,
      'role': role,
      'content': content,
      'citations': citations ?? [],
    });
  }
}

