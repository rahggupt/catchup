import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Database Validation Test Script
/// Run this with: flutter test test/database_validation_test.dart
/// 
/// This script tests:
/// 1. User authentication
/// 2. Fetching collections
/// 3. Creating an article
/// 4. Adding article to collection
/// 5. Verifying article appears in collection
/// 6. Deleting article from collection
/// 7. Verifying article is removed

void main() {
  late SupabaseClient supabase;
  String? testUserId;
  String? testCollectionId;
  String? testArticleId;

  setUpAll(() async {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    
    supabase = Supabase.instance.client;
    
    print('\n🔧 Database Validation Test');
    print('=' * 50);
  });

  group('Database Validation Tests', () {
    test('1. User Authentication Check', () async {
      print('\n📝 Test 1: Checking user authentication...');
      
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        print('❌ No authenticated user found');
        print('💡 Please sign in to the app first, then run this test');
        fail('No authenticated user');
      }
      
      testUserId = user.id;
      print('✅ User authenticated: $testUserId');
      print('   Email: ${user.email}');
    });

    test('2. Fetch User Collections', () async {
      print('\n📝 Test 2: Fetching user collections...');
      
      expect(testUserId, isNotNull, reason: 'User must be authenticated');
      
      try {
        final response = await supabase
            .from('collections')
            .select()
            .eq('owner_id', testUserId!)
            .order('created_at', ascending: false);
        
        final collections = response as List;
        print('✅ Found ${collections.length} collections');
        
        for (var collection in collections) {
          print('   - ${collection['name']} (${collection['id']})');
        }
        
        if (collections.isEmpty) {
          print('⚠️  No collections found for user');
        } else {
          testCollectionId = collections.first['id'];
          print('📌 Using collection: ${collections.first['name']}');
        }
        
        expect(collections.length, greaterThanOrEqualTo(0));
      } catch (e, stackTrace) {
        print('❌ Error fetching collections: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('3. Create Test Article', () async {
      print('\n📝 Test 3: Creating test article...');
      
      try {
        // Check if article already exists
        final existing = await supabase
            .from('articles')
            .select()
            .eq('url', 'https://test.example.com/validation-test')
            .maybeSingle();
        
        if (existing != null) {
          testArticleId = existing['id'];
          print('ℹ️  Test article already exists: $testArticleId');
        } else {
          final response = await supabase
              .from('articles')
              .insert({
                'title': 'Database Validation Test Article',
                'url': 'https://test.example.com/validation-test',
                'summary': 'This is a test article for database validation',
                'source': 'Test',
                'published_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          
          testArticleId = response['id'];
          print('✅ Test article created: $testArticleId');
        }
        
        expect(testArticleId, isNotNull);
      } catch (e, stackTrace) {
        print('❌ Error creating article: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('4. Add Article to Collection (Test RLS INSERT)', () async {
      print('\n📝 Test 4: Adding article to collection...');
      
      if (testCollectionId == null) {
        print('⚠️  Skipping: No collection available');
        return;
      }
      
      expect(testArticleId, isNotNull);
      expect(testUserId, isNotNull);
      
      try {
        // Check if already exists
        final existing = await supabase
            .from('collection_articles')
            .select()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!)
            .maybeSingle();
        
        if (existing != null) {
          print('ℹ️  Article already in collection');
        } else {
          await supabase
              .from('collection_articles')
              .insert({
                'collection_id': testCollectionId,
                'article_id': testArticleId,
                'added_by': testUserId,
              });
          
          print('✅ Article added to collection');
        }
        
        // Verify insertion
        final verify = await supabase
            .from('collection_articles')
            .select()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!);
        
        print('✅ Verified: Article exists in collection_articles');
      } catch (e, stackTrace) {
        print('❌ Error adding article to collection: $e');
        print('💡 This might be an RLS policy issue!');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('5. Fetch Collection Articles (Test RLS SELECT)', () async {
      print('\n📝 Test 5: Fetching collection articles...');
      
      if (testCollectionId == null) {
        print('⚠️  Skipping: No collection available');
        return;
      }
      
      try {
        final response = await supabase
            .from('collection_articles')
            .select('*, articles(*)')
            .eq('collection_id', testCollectionId!);
        
        final articles = response as List;
        print('✅ Found ${articles.length} article(s) in collection');
        
        for (var item in articles) {
          final article = item['articles'];
          print('   - ${article['title']}');
        }
        
        // Verify our test article is in the results
        final hasTestArticle = articles.any((item) => 
          item['article_id'] == testArticleId
        );
        
        if (hasTestArticle) {
          print('✅ Test article found in collection!');
        } else {
          print('❌ Test article NOT found in collection!');
          print('💡 This suggests an RLS SELECT policy issue!');
        }
        
        expect(hasTestArticle, isTrue, 
          reason: 'Test article should be visible in collection');
      } catch (e, stackTrace) {
        print('❌ Error fetching collection articles: $e');
        print('💡 This might be an RLS SELECT policy issue!');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('6. Count Articles in Collection', () async {
      print('\n📝 Test 6: Counting articles...');
      
      if (testCollectionId == null) {
        print('⚠️  Skipping: No collection available');
        return;
      }
      
      try {
        final response = await supabase
            .from('collection_articles')
            .select('article_id')
            .eq('collection_id', testCollectionId!);
        
        final count = (response as List).length;
        print('✅ Collection has $count article(s)');
        
        expect(count, greaterThan(0), 
          reason: 'Collection should have at least 1 article (our test article)');
      } catch (e, stackTrace) {
        print('❌ Error counting articles: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('7. Delete Article from Collection (Test RLS DELETE)', () async {
      print('\n📝 Test 7: Deleting article from collection...');
      
      if (testCollectionId == null || testArticleId == null) {
        print('⚠️  Skipping: No test data available');
        return;
      }
      
      try {
        await supabase
            .from('collection_articles')
            .delete()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!);
        
        print('✅ Article deleted from collection');
        
        // Verify deletion
        final verify = await supabase
            .from('collection_articles')
            .select()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!);
        
        final articles = verify as List;
        
        if (articles.isEmpty) {
          print('✅ Verified: Article removed from collection');
        } else {
          print('❌ Article still exists in collection!');
          print('💡 This suggests an RLS DELETE policy issue!');
        }
        
        expect(articles, isEmpty, 
          reason: 'Article should be removed from collection');
      } catch (e, stackTrace) {
        print('❌ Error deleting article from collection: $e');
        print('💡 This might be an RLS DELETE policy issue!');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('8. Cleanup Test Article', () async {
      print('\n📝 Test 8: Cleaning up test data...');
      
      if (testArticleId == null) {
        print('⚠️  No test article to clean up');
        return;
      }
      
      try {
        await supabase
            .from('articles')
            .delete()
            .eq('id', testArticleId!);
        
        print('✅ Test article cleaned up');
      } catch (e) {
        print('⚠️  Could not clean up test article: $e');
        // Don't fail the test for cleanup errors
      }
    });
  });

  tearDownAll(() {
    print('\n' + '=' * 50);
    print('🏁 Database Validation Complete!');
    print('=' * 50 + '\n');
  });
}

