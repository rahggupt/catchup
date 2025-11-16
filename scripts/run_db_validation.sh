#!/bin/bash

# Database Validation Script
# This script runs local tests to validate database operations and RLS policies

set -e

echo "🧪 CatchUp Database Validation"
echo "================================"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "💡 Please create .env file with your Supabase credentials"
    exit 1
fi

echo "✅ Found .env file"
echo ""

# Check if user is authenticated
echo "📝 Step 1: Checking authentication..."
echo "💡 Make sure you're signed in to the app before running this test"
echo ""
read -p "Have you signed in to the app? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⚠️  Please sign in to the app first, then run this script again"
    exit 1
fi

echo ""
echo "🔧 Step 2: Running validation tests..."
echo ""

# Run the validation test
flutter test test/database_validation_test.dart --reporter=expanded

echo ""
echo "================================"
echo "🏁 Validation Complete!"
echo ""
echo "📊 Results Summary:"
echo "   If all tests passed (✅), your database and RLS policies are working!"
echo "   If any test failed (❌), check the error messages above."
echo ""
echo "💡 Common Issues:"
echo "   - RLS policy missing: Run the SQL fix in Supabase"
echo "   - Authentication error: Sign in to the app first"
echo "   - Connection error: Check your .env file"
echo ""

