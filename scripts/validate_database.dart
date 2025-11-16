#!/usr/bin/env dart

import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

/// Standalone Database Validation Script
/// Run with: dart scripts/validate_database.dart
/// 
/// This validates database operations and RLS policies

Future<void> main() async {
  print('\n🧪 CatchUp Database Validation');
  print('=' * 50);
  print('');

  // Load .env
  final env = DotEnv()..load();
  
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env');
    exit(1);
  }

  print('✅ Loaded Supabase credentials from .env');
  print('');

  // Initialize Supabase client
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  
  String? testUserId;
  String? testCollectionId;
  String? testArticleId;
  
  try {
    // Test 1: Check authentication
    print('📝 Test 1: Checking authentication...');
    
    // Try to get user from stored session (if any)
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      print('❌ No authenticated user found');
      print('');
      print('💡 To authenticate, you need to:');
      print('   1. Sign in to the app on your phone');
      print('   2. The app will store the session');
      print('   3. Or provide email/password to this script');
      print('');
      print('❗ For now, let me check if we can access the database directly...');
      print('');
    } else {
      testUserId = user.id;
      print('✅ User authenticated: $testUserId');
      print('   Email: ${user.email}');
      print('');
    }

    // Test 2: Fetch collections (this will test RLS)
    print('📝 Test 2: Testing database access...');
    
    try {
      final response = await supabase
          .from('collections')
          .select()
          .limit(5);
      
      final collections = response as List;
      print('✅ Successfully connected to database');
      print('   Found ${collections.length} collections');
      
      if (collections.isEmpty) {
        print('   ⚠️  No collections found (this is okay if you\'re a new user)');
      } else {
        print('');
        print('   Collections:');
        for (var col in collections) {
          print('   - ${col['name']} (${col['id']})');
          if (testCollectionId == null) {
            testCollectionId = col['id'];
          }
        }
      }
      print('');
    } catch (e) {
      print('❌ Error accessing collections table: $e');
      print('💡 This might be an RLS policy issue on collections table');
      print('');
    }

    // Test 3: Check collection_articles table
    print('📝 Test 3: Checking collection_articles table...');
    
    if (testCollectionId == null) {
      print('⚠️  Skipping: No collection available to test with');
      print('');
    } else {
      try {
        final response = await supabase
            .from('collection_articles')
            .select('*, articles(*)')
            .eq('collection_id', testCollectionId!)
            .limit(5);
        
        final articles = response as List;
        print('✅ Successfully accessed collection_articles table');
        print('   Found ${articles.length} articles in collection');
        
        if (articles.isEmpty) {
          print('   ℹ️  Collection is empty (0 articles)');
        } else {
          print('');
          print('   Articles:');
          for (var item in articles) {
            final article = item['articles'];
            if (article != null) {
              print('   - ${article['title']}');
            }
          }
        }
        print('');
        
        print('✅ RLS SELECT policy is working!');
        print('');
      } catch (e) {
        print('❌ Error accessing collection_articles: $e');
        print('');
        print('💡 This suggests the RLS SELECT policy is missing!');
        print('   Run this SQL in Supabase:');
        print('');
        print('''
CREATE POLICY "collection_articles_select" ON collection_articles
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members WHERE user_id = auth.uid()
  )
);
''');
        print('');
      }
    }

    // Test 4: Try to insert (if we have a collection)
    if (testCollectionId != null && testUserId != null) {
      print('📝 Test 4: Testing INSERT operation...');
      
      try {
        // First create a test article
        final articleResponse = await supabase
            .from('articles')
            .upsert({
              'id': '00000000-0000-4000-8000-000000000001',
              'title': 'Test Article for Validation',
              'url': 'https://test.validation.example.com',
              'summary': 'This is a test article',
              'source': 'Test',
              'published_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        
        testArticleId = articleResponse['id'];
        print('✅ Test article created: $testArticleId');
        
        // Try to add it to collection
        await supabase
            .from('collection_articles')
            .insert({
              'collection_id': testCollectionId,
              'article_id': testArticleId,
              'added_by': testUserId,
            });
        
        print('✅ Successfully added article to collection');
        print('✅ RLS INSERT policy is working!');
        print('');
        
        // Verify it's there
        final verify = await supabase
            .from('collection_articles')
            .select()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!);
        
        if ((verify as List).isNotEmpty) {
          print('✅ Verified: Article exists in collection');
          print('');
        }
        
      } catch (e) {
        print('❌ Error inserting article: $e');
        print('');
        print('💡 This suggests the RLS INSERT policy is missing!');
        print('   Run this SQL in Supabase:');
        print('');
        print('''
CREATE POLICY "collection_articles_insert" ON collection_articles
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections WHERE owner_id = auth.uid()
    UNION
    SELECT collection_id FROM collection_members 
    WHERE user_id = auth.uid() AND role IN ('editor', 'admin')
  )
);
''');
        print('');
      }
    }

    // Test 5: Cleanup
    if (testArticleId != null && testCollectionId != null) {
      print('📝 Test 5: Cleaning up test data...');
      
      try {
        await supabase
            .from('collection_articles')
            .delete()
            .eq('collection_id', testCollectionId!)
            .eq('article_id', testArticleId!);
        
        await supabase
            .from('articles')
            .delete()
            .eq('id', testArticleId!);
        
        print('✅ Test data cleaned up');
        print('');
      } catch (e) {
        print('⚠️  Could not clean up: $e');
        print('');
      }
    }

  } catch (e, stackTrace) {
    print('❌ Unexpected error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }

  print('=' * 50);
  print('🏁 Validation Complete!');
  print('=' * 50);
  print('');
  print('📊 Summary:');
  print('   If you see ✅ for all tests, your database is configured correctly!');
  print('   If you see ❌, follow the SQL fix instructions above.');
  print('');
}

