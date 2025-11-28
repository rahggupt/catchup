import '../../core/config/supabase_config.dart';
import '../models/article_model.dart';
import '../models/collection_model.dart';
import '../models/source_model.dart';
import '../models/user_model.dart';
import 'logger_service.dart';

/// Service for Supabase database operations
class SupabaseService {
  final _client = SupabaseConfig.client;
  final LoggerService _logger = LoggerService();

  // ===== Articles =====
  
  Future<List<ArticleModel>> getArticles({int limit = 20}) async {
    try {
      _logger.info('Fetching articles (limit: $limit)', category: 'Database');
      final response = await _client
          .from('articles')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
      final articles = (response as List)
          .map((json) => ArticleModel.fromJson(json))
          .toList();
      _logger.success('Fetched ${articles.length} articles', category: 'Database');
      return articles;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch articles', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ArticleModel> createArticle(ArticleModel article) async {
    try {
      _logger.info('Checking if article exists: ${article.title} (${article.id})', category: 'Database');
      
      // Check if article already exists
      final existingResponse = await _client
          .from('articles')
          .select()
          .eq('id', article.id)
          .maybeSingle();
      
      if (existingResponse != null) {
        _logger.info('Article already exists, returning existing', category: 'Database');
        return ArticleModel.fromJson(existingResponse);
      }
      
      _logger.info('Creating new article in database', category: 'Database');
      final response = await _client
          .from('articles')
          .insert(article.toJson())
          .select()
          .single();
      
      _logger.success('Article created successfully', category: 'Database');
      return ArticleModel.fromJson(response);
    } catch (e, stackTrace) {
      _logger.error('Failed to create article: ${article.title}', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ===== Collections =====
  
  Future<List<CollectionModel>> getUserCollections(String userId) async {
    try {
      _logger.info('Fetching collections for user: $userId', category: 'Database');
      
      // First, get collections where user is owner
      final ownedResponse = await _client
          .from('collections')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      
      _logger.info('Found ${(ownedResponse as List).length} owned collections', category: 'Database');
      
      // Then get collections where user is a member
      List memberCollectionIds = [];
      try {
        final memberResponse = await _client
            .from('collection_members')
            .select('collection_id')
            .eq('user_id', userId);
        
        memberCollectionIds = (memberResponse as List)
            .map((m) => m['collection_id'])
            .toList();
        
        _logger.info('Found ${memberCollectionIds.length} member collection IDs', category: 'Database');
      } catch (e) {
        _logger.warning('Could not fetch member collections: $e', category: 'Database');
      }
      
      // Fetch member collections if any
      List<Map<String, dynamic>> allCollectionData = List.from(ownedResponse);
      
      if (memberCollectionIds.isNotEmpty) {
        final memberCollectionsResponse = await _client
            .from('collections')
            .select()
            .inFilter('id', memberCollectionIds);
        
        allCollectionData.addAll(List.from(memberCollectionsResponse));
      }
      
      // Remove duplicates and convert to models
      final uniqueCollections = <String, CollectionModel>{};
      for (final json in allCollectionData) {
        final collection = CollectionModel.fromJson(json);
        uniqueCollections[collection.id] = collection;
      }
      
      final collections = uniqueCollections.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _logger.success('Fetched ${collections.length} total collections (owned + member)', category: 'Database');
      return collections;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch collections for user: $userId', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<CollectionModel> createCollection({
    required String name,
    required String ownerId,
    required String privacy,
    String? preview,
  }) async {
    try {
      _logger.info('Creating collection: $name for user: $ownerId', category: 'Database');
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
      
      _logger.success('Collection created: $name', category: 'Database');
      return CollectionModel.fromJson(response);
    } catch (e, stackTrace) {
      _logger.error('Failed to create collection: $name', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
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

  /// Recalculate and update collection stats (article count, chat count, contributor count)
  Future<void> recalculateCollectionStats(String collectionId) async {
    try {
      _logger.info('Recalculating stats for collection: $collectionId', category: 'Database');
      
      // If SQL function exists, call it
      try {
        await _client.rpc('recalculate_collection_stats', params: {'coll_id': collectionId});
        _logger.success('Stats recalculated via SQL function', category: 'Database');
        return;
      } catch (e) {
        // SQL function doesn't exist, calculate manually
        _logger.warning('SQL function not found, calculating manually', category: 'Database');
      }
      
      // Manual calculation fallback
      // Count articles
      final articlesResponse = await _client
          .from('collection_articles')
          .select('article_id, added_by')
          .eq('collection_id', collectionId);
      
      final articles = articlesResponse as List;
      final articleCount = articles.length;
      final contributorIds = articles.map((a) => a['added_by']).toSet();
      final contributorCount = contributorIds.isEmpty ? 1 : contributorIds.length;
      
      // Count chats
      final chatsResponse = await _client
          .from('chats')
          .select('id')
          .eq('collection_id', collectionId);
      final chatCount = (chatsResponse as List).length;
      
      // Update stats
      await _client
          .from('collections')
          .update({
            'stats': {
              'article_count': articleCount,
              'chat_count': chatCount,
              'contributor_count': contributorCount,
            }
          })
          .eq('id', collectionId);
      
      _logger.success('Collection stats recalculated: articles=$articleCount, chats=$chatCount, contributors=$contributorCount', category: 'Database');
    } catch (e, stackTrace) {
      _logger.error('Failed to recalculate collection stats', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
      _logger.info('Checking if article already in collection (collection: $collectionId, article: $articleId)', category: 'Database');
      
      // Check if already exists
      final existing = await _client
          .from('collection_articles')
          .select()
          .eq('collection_id', collectionId)
          .eq('article_id', articleId)
          .maybeSingle();
      
      if (existing != null) {
        _logger.warning('Article already in collection, skipping', category: 'Database');
        return;
      }
      
      _logger.info('Adding article to collection', category: 'Database');
      
      await _client.from('collection_articles').insert({
        'collection_id': collectionId,
        'article_id': articleId,
        'added_by': addedBy,
      });
      
      _logger.success('Article added to collection successfully', category: 'Database');
      
      // Recalculate collection stats immediately
      _logger.info('Recalculating collection stats after adding article', category: 'Database');
      await recalculateCollectionStats(collectionId);
      
      // Update user stats - increment articles count
      await _incrementUserStat(addedBy, 'articles');
    } catch (e, stackTrace) {
      _logger.error('Failed to add article to collection (collection: $collectionId, article: $articleId)', 
        category: 'Database', error: e, stackTrace: stackTrace);
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

  /// Update collection with arbitrary fields
  Future<void> updateCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      _logger.info('Updating collection: $collectionId with ${updates.keys.join(", ")}', category: 'Database');
      
      await _client
          .from('collections')
          .update(updates)
          .eq('id', collectionId);
      
      _logger.success('Collection updated successfully', category: 'Database');
    } catch (e, stackTrace) {
      _logger.error('Failed to update collection', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Remove an article from a collection
  Future<void> removeArticleFromCollection({
    required String collectionId,
    required String articleId,
  }) async {
    try {
      _logger.info('Removing article from collection (collection: $collectionId, article: $articleId)', category: 'Database');
      
      await _client
          .from('collection_articles')
          .delete()
          .eq('collection_id', collectionId)
          .eq('article_id', articleId);
      
      _logger.success('Article removed from collection successfully', category: 'Database');
    } catch (e, stackTrace) {
      _logger.error('Failed to remove article from collection', category: 'Database', error: e, stackTrace: stackTrace);
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

  /// Generate a shareable link for a collection
  Future<String> generateShareableLink(String collectionId) async {
    try {
      _logger.info('Generating shareable link for collection: $collectionId', category: 'Database');
      
      // Try to call SQL function first
      try {
        final result = await _client.rpc('generate_shareable_token', params: {'coll_id': collectionId});
        final token = result as String;
        
        // Update collection to enable sharing
        await _client
            .from('collections')
            .update({'share_enabled': true})
            .eq('id', collectionId);
        
        _logger.success('Shareable link generated with SQL function', category: 'Database');
        // TODO: Replace with your actual domain when deploying
        // For Firebase Dynamic Links: https://catchup.page.link/c?token=$token
        // For custom domain: https://catchup.app/c/$token
        return 'https://catchup.app/c/$token';
      } catch (e) {
        // SQL function doesn't exist, generate token manually
        _logger.warning('SQL function not found, generating token manually', category: 'Database');
        
        // Generate a random token (URL-safe)
        final collectionIdPart = collectionId.length >= 8 ? collectionId.substring(0, 8) : collectionId;
        final random = DateTime.now().millisecondsSinceEpoch.toString() + collectionIdPart;
        final hashString = random.hashCode.abs().toRadixString(36);
        final token = hashString.substring(0, hashString.length < 12 ? hashString.length : 12).padRight(12, '0');
        
        // Update collection with token
        await _client
            .from('collections')
            .update({
              'shareable_token': token,
              'share_enabled': true,
            })
            .eq('id', collectionId);
        
        _logger.success('Shareable link generated manually: $token', category: 'Database');
        // TODO: Replace with your actual domain when deploying
        // For Firebase Dynamic Links: https://catchup.page.link/c?token=$token
        // For custom domain: https://catchup.app/c/$token
        return 'https://catchup.app/c/$token';
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to generate shareable link', category: 'Database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get collection by shareable token
  Future<Map<String, dynamic>?> getCollectionByToken(String token) async {
    try {
      _logger.info('Fetching collection by token', category: 'Database');
      
      final response = await _client
          .from('collections')
          .select('*, owner:users!owner_id(email, raw_user_meta_data)')
          .eq('shareable_token', token)
          .eq('share_enabled', true)
          .maybeSingle();
      
      if (response == null) {
        _logger.warning('No collection found for token', category: 'Database');
        return null;
      }
      
      _logger.success('Collection found by token', category: 'Database');
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch collection by token', category: 'Database', error: e, stackTrace: stackTrace);
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
      _logger.info('Sending collection invite to: $inviteeEmail', category: 'Database');
      
      await _client.from('collection_invites').insert({
        'collection_id': collectionId,
        'inviter_id': inviterId,
        'invitee_email': inviteeEmail,
        'expires_at': expiresAt?.toIso8601String(),
      });
      
      _logger.success('Collection invite sent successfully', category: 'Database');
    } catch (e, stackTrace) {
      _logger.error('Failed to send collection invite', category: 'Database', error: e, stackTrace: stackTrace);
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

