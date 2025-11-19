-- =====================================================
-- DIAGNOSTIC: Find What's Causing RLS Recursion
-- =====================================================
-- Run this to see exactly what policies exist and which might be problematic
-- =====================================================

-- =====================================================
-- 1. Show ALL policies on collections table
-- =====================================================

SELECT 
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies 
WHERE tablename = 'collections'
ORDER BY cmd, policyname;

-- Count how many policies exist
SELECT 
  'Total collections policies' as info,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 4 THEN '✓ CORRECT (should be 4)'
    WHEN COUNT(*) > 4 THEN '✗ TOO MANY - duplicate policies causing issues'
    WHEN COUNT(*) < 4 THEN '✗ TOO FEW - missing policies'
  END as status
FROM pg_policies 
WHERE tablename = 'collections';

-- =====================================================
-- 2. Show ALL policies on collection_members table
-- =====================================================

SELECT 
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies 
WHERE tablename = 'collection_members'
ORDER BY cmd, policyname;

-- Count collection_members policies
SELECT 
  'Total collection_members policies' as info,
  COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'collection_members';

-- =====================================================
-- 3. Check for problematic patterns in policies
-- =====================================================

-- Policies that might reference collaborator_ids (causes recursion)
SELECT 
  tablename,
  policyname,
  'References collaborator_ids' as issue
FROM pg_policies 
WHERE tablename = 'collections'
AND (qual::text ILIKE '%collaborator%' OR with_check::text ILIKE '%collaborator%');

-- Policies that use ANY() operations (might cause recursion)
SELECT 
  tablename,
  policyname,
  'Uses ANY() operation' as issue
FROM pg_policies 
WHERE tablename = 'collections'
AND (qual::text ILIKE '%ANY%' OR with_check::text ILIKE '%ANY%');

-- Policies that might query collections from within collections policy
SELECT 
  tablename,
  policyname,
  'Might cause recursion' as issue,
  substring(qual::text, 1, 100) as policy_snippet
FROM pg_policies 
WHERE tablename = 'collections'
AND cmd = 'SELECT'
AND qual::text NOT LIKE '%auth.uid() = owner_id%';

-- =====================================================
-- 4. Check RLS is enabled
-- =====================================================

SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('collections', 'collection_members')
ORDER BY tablename;

-- =====================================================
-- 5. List all policy names for easy DROP commands
-- =====================================================

SELECT 
  'DROP POLICY IF EXISTS "' || policyname || '" ON ' || tablename || ';' as drop_command
FROM pg_policies 
WHERE tablename IN ('collections', 'collection_members')
ORDER BY tablename, policyname;

-- =====================================================
-- INTERPRETATION GUIDE:
-- =====================================================
-- 
-- If you see:
-- - More than 4 policies on collections → Run NUCLEAR_RLS_FIX.sql
-- - Policies with "collaborator" in the name → These cause recursion
-- - Policies with ANY() operations → These might cause recursion
-- - Policies that don't check "auth.uid() = owner_id" → Suspicious
-- 
-- Copy the DROP commands from section 5 and run them, then run
-- COMPLETE_RLS_FIX.sql to recreate clean policies.
-- =====================================================

