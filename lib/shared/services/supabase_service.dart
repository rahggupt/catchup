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
    try {
      print('🔍 Checking if article exists: ${article.id}');
      
      // Check if article already exists
      final existingResponse = await _client
          .from('articles')
          .select()
          .eq('id', article.id)
          .maybeSingle();
      
      if (existingResponse != null) {
        print('✅ Article already exists, returning existing');
        return ArticleModel.fromJson(existingResponse);
      }
      
      print('💾 Creating new article in database');
      final response = await _client
          .from('articles')
          .insert(article.toJson())
          .select()
          .single();
      
      print('✅ Article created successfully');
      return ArticleModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating article: $e');
      rethrow;
    }
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

  Future<void> deleteSource(String sourceId) async {
    await _client
        .from('sources')
        .delete()
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
    try {
      print('🔍 Checking if article is already in collection');
      
      // Check if already exists
      final existing = await _client
          .from('collection_articles')
          .select()
          .eq('collection_id', collectionId)
          .eq('article_id', articleId)
          .maybeSingle();
      
      if (existing != null) {
        print('⚠️ Article already in collection, skipping');
        return;
      }
      
      print('💾 Adding article to collection');
      print('   Collection ID: $collectionId');
      print('   Article ID: $articleId');
      print('   Added By: $addedBy');
      
      await _client.from('collection_articles').insert({
        'collection_id': collectionId,
        'article_id': articleId,
        'added_by': addedBy,
      });
      
      print('✅ Article added to collection successfully');
      
      // Update user stats - increment articles count
      await _incrementUserStat(addedBy, 'articles');
    } catch (e) {
      print('❌ Error adding article to collection: $e');
      print('   Error details: ${e.toString()}');
      rethrow;
    }
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

  // ===== Collection Sharing & Privacy =====
  
  /// Generate a shareable link for a collection
  Future<String> generateShareableLink(String collectionId) async {
    try {
      // Call the database function to generate a unique token
      final response = await _client
          .rpc('generate_shareable_token')
          .select()
          .single();
      
      final token = response as String;
      
      // Update the collection with the token and enable sharing
      await _client
          .from('collections')
          .update({
            'shareable_token': token,
            'share_enabled': true,
          })
          .eq('id', collectionId);
      
      return token;
    } catch (e) {
      print('❌ Error generating shareable link: $e');
      rethrow;
    }
  }

  /// Disable sharing for a collection
  Future<void> disableSharing(String collectionId) async {
    try {
      await _client
          .from('collections')
          .update({
            'share_enabled': false,
          })
          .eq('id', collectionId);
    } catch (e) {
      print('❌ Error disabling sharing: $e');
      rethrow;
    }
  }

  /// Update collection privacy setting
  Future<void> updateCollectionPrivacy(
    String collectionId, 
    String privacy,
  ) async {
    try {
      await _client
          .from('collections')
          .update({'privacy': privacy})
          .eq('id', collectionId);
    } catch (e) {
      print('❌ Error updating collection privacy: $e');
      rethrow;
    }
  }

  /// Add a member to a collection
  Future<void> addCollectionMember({
    required String collectionId,
    required String userId,
    required String role,
    String? invitedBy,
  }) async {
    try {
      await _client.from('collection_members').insert({
        'collection_id': collectionId,
        'user_id': userId,
        'role': role,
        'invited_by': invitedBy,
      });
    } catch (e) {
      print('❌ Error adding collection member: $e');
      rethrow;
    }
  }

  /// Remove a member from a collection
  Future<void> removeCollectionMember({
    required String collectionId,
    required String userId,
  }) async {
    try {
      await _client
          .from('collection_members')
          .delete()
          .eq('collection_id', collectionId)
          .eq('user_id', userId);
    } catch (e) {
      print('❌ Error removing collection member: $e');
      rethrow;
    }
  }

  /// Get all members of a collection
  Future<List<Map<String, dynamic>>> getCollectionMembers(
    String collectionId,
  ) async {
    try {
      final response = await _client
          .from('collection_members')
          .select('*, user:users!user_id(email, raw_user_meta_data)')
          .eq('collection_id', collectionId)
          .order('joined_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error getting collection members: $e');
      rethrow;
    }
  }

  /// Send an invite to join a collection
  Future<void> sendCollectionInvite({
    required String collectionId,
    required String inviterId,
    required String inviteeEmail,
    DateTime? expiresAt,
  }) async {
    try {
      await _client.from('collection_invites').insert({
        'collection_id': collectionId,
        'inviter_id': inviterId,
        'invitee_email': inviteeEmail,
        'expires_at': expiresAt?.toIso8601String(),
      });
    } catch (e) {
      print('❌ Error sending collection invite: $e');
      rethrow;
    }
  }

  /// Accept a collection invite
  Future<void> acceptCollectionInvite(String inviteId) async {
    try {
      await _client.rpc('accept_collection_invite', params: {
        'invite_id': inviteId,
      });
    } catch (e) {
      print('❌ Error accepting collection invite: $e');
      rethrow;
    }
  }

  /// Get pending invites for the current user
  Future<List<Map<String, dynamic>>> getPendingInvites() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final response = await _client
          .from('collection_invites')
          .select('*, collection:collections(name), inviter:users!inviter_id(email)')
          .eq('invitee_email', user.email!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error getting pending invites: $e');
      rethrow;
    }
  }

  /// Check if user has access to a collection
  Future<bool> userHasCollectionAccess({
    required String userId,
    required String collectionId,
  }) async {
    try {
      // Check if user owns the collection
      final collectionResponse = await _client
          .from('collections')
          .select()
          .eq('id', collectionId)
          .eq('owner_id', userId)
          .maybeSingle();
      
      if (collectionResponse != null) return true;
      
      // Check if user is a member
      final memberResponse = await _client
          .from('collection_members')
          .select()
          .eq('collection_id', collectionId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (memberResponse != null) return true;
      
      // Check if collection is public with sharing enabled
      final publicResponse = await _client
          .from('collections')
          .select()
          .eq('id', collectionId)
          .eq('privacy', 'public')
          .eq('share_enabled', true)
          .maybeSingle();
      
      return publicResponse != null;
    } catch (e) {
      print('❌ Error checking collection access: $e');
      return false;
    }
  }
}

