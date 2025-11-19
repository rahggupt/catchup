# 🧪 API Test Suite Documentation

Complete test coverage for all external API integrations in the CatchUp app.

---

## 📋 Test Coverage

### 1. **Supabase API Tests** (4 tests)
- ✅ Connection test
- ✅ Auth endpoint test
- ✅ Database query test
- ✅ Realtime connection test

### 2. **Gemini API Tests** (2 tests)
- ✅ Connection test
- ✅ Content generation test

### 3. **Qdrant API Tests** (3 tests)
- ✅ Connection test
- ✅ Health check
- ✅ Collection creation test

### 4. **Hugging Face API Tests** (2 tests)
- ✅ Connection test
- ✅ Model availability test

### 5. **RSS Feed Tests** (4 tests)
- ✅ TechCrunch RSS
- ✅ Ars Technica RSS
- ✅ Wired RSS
- ✅ CORS proxy test

### 6. **Integration Tests** (2 tests)
- ✅ Full RAG pipeline simulation
- ✅ Database + Auth integration

### 7. **Performance Tests** (3 tests)
- ✅ Gemini response time
- ✅ Qdrant response time
- ✅ Supabase response time

**Total: 20 comprehensive tests**

---

## 🚀 Quick Start

### Prerequisites

Ensure your `.env` file contains all required API keys:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
GEMINI_API_KEY=your_gemini_key
QDRANT_API_URL=https://your-cluster.api.qdrant.io
QDRANT_API_KEY=your_qdrant_key
HUGGING_FACE_API_KEY=your_hf_key
```

### Run All Tests

```bash
# Make script executable
chmod +x run_tests.sh

# Run complete test suite
./run_tests.sh
```

### Run Specific Test Groups

```bash
# Run only Supabase tests
flutter test test/api_test_suite.dart --name "Supabase"

# Run only AI tests (Gemini + HuggingFace)
flutter test test/api_test_suite.dart --name "Gemini|Hugging Face"

# Run only performance tests
flutter test test/api_test_suite.dart --name "Performance"
```

---

## 📊 Test Results

### Expected Output

```
🧪 Starting API Test Suite...

✅ 1. Supabase API Tests
   ✅ Supabase connection successful
   ✅ Supabase auth endpoint accessible
   ✅ Supabase database query successful
   ✅ Supabase realtime URL format valid

✅ 2. Gemini API Tests
   ✅ Gemini API connection successful
      Available models: 5
   ✅ Gemini content generation successful

✅ 3. Qdrant API Tests
   ✅ Qdrant connection successful
      Collections: 3
   ✅ Qdrant health check passed
   ✅ Qdrant collection creation test passed

✅ 4. Hugging Face API Tests
   ✅ Hugging Face API connection successful
      Embedding dimensions: 384
   ✅ Hugging Face model available

✅ 5. RSS Feed Tests
   ✅ TechCrunch RSS feed accessible
   ✅ Ars Technica RSS feed accessible
   ✅ Wired RSS feed accessible
   ✅ CORS proxy functional

✅ 6. Integration Tests
   🔄 Testing full RAG pipeline...
      1. Generating embeddings...
      ✅ Embeddings generated
      2. Checking Qdrant...
      ✅ Qdrant accessible
      3. Testing Gemini...
      ✅ Gemini responded
   ✅ Full RAG pipeline functional!
   ✅ Database schema validation passed

✅ 7. Performance Tests
   ✅ Gemini response time: 450ms
   ✅ Qdrant response time: 120ms
   ✅ Supabase response time: 180ms

✅ API Test Suite Complete!

All tests passed! (20 passed, 0 failed)
```

---

## 🔍 Test Details

### Supabase Tests

**Purpose:** Verify backend database and auth connectivity

**What's Tested:**
- REST API endpoint availability
- Authentication service status
- Database table access (collections, articles, chats, etc.)
- Realtime websocket URL format

**Common Issues:**
- Invalid credentials → Check `.env` file
- RLS policies blocking → Verify Supabase policies
- Network timeout → Check internet connection

---

### Gemini API Tests

**Purpose:** Verify AI response generation

**What's Tested:**
- API key validity
- Model availability (gemini-pro)
- Content generation capability
- Response format correctness

**Common Issues:**
- 403 error → Invalid API key
- Rate limit → Wait and retry
- Slow response → Normal for first request

**Performance Benchmarks:**
- Connection: < 2s
- Content generation: < 10s

---

### Qdrant API Tests

**Purpose:** Verify vector database for RAG

**What's Tested:**
- Connection and authentication
- Health status
- Collection CRUD operations
- Vector storage capability

**Common Issues:**
- 401 error → Check API key
- Collection exists → Tests clean up automatically
- Timeout → Check Qdrant cluster status

**Performance Benchmarks:**
- Connection: < 1s
- Collection creation: < 2s

---

### Hugging Face API Tests

**Purpose:** Verify embedding generation

**What's Tested:**
- API authentication
- Model availability (all-MiniLM-L6-v2)
- Embedding generation
- Vector dimensions (384)

**Common Issues:**
- 503 error → Model loading, retry with `wait_for_model`
- Rate limit → Free tier: 30 req/min
- Slow first request → Model cold start

**Performance Benchmarks:**
- First request: < 30s (model loading)
- Subsequent: < 3s

---

### RSS Feed Tests

**Purpose:** Verify article sources are accessible

**What's Tested:**
- RSS feed availability
- XML format validity
- CORS proxy functionality (for web)
- Response headers

**Common Issues:**
- 403 error → User-Agent header required
- CORS error → Use proxy for web builds
- Feed moved → Update URL in source config

---

### Integration Tests

**Purpose:** Verify complete workflows

**Full RAG Pipeline:**
1. Generate query embeddings (Hugging Face)
2. Search vector database (Qdrant)
3. Retrieve context articles
4. Generate AI response (Gemini)
5. Return answer with citations

**Database + Auth:**
- Verify all tables exist
- Check RLS policies
- Test real-time subscriptions

---

### Performance Tests

**Purpose:** Ensure acceptable response times

**Thresholds:**
- **Gemini:** < 5s (API calls)
- **Qdrant:** < 3s (vector search)
- **Supabase:** < 2s (database queries)

**Action if Failed:**
- Check network latency
- Verify API region proximity
- Consider caching strategies

---

## 🐛 Troubleshooting

### All Tests Skipped

**Issue:** Environment variables not loaded

**Solution:**
```bash
# Verify .env file exists
ls -la .env

# Check environment variables
source .env && env | grep API

# Run with explicit variables
GEMINI_API_KEY=your_key flutter test test/api_test_suite.dart
```

---

### Individual Test Failures

**Supabase 401 Error:**
```
Solution: Verify SUPABASE_ANON_KEY is correct
Check: Supabase Dashboard → Settings → API
```

**Gemini 403 Error:**
```
Solution: Generate new API key
Check: https://makersuite.google.com/app/apikey
```

**Qdrant Connection Timeout:**
```
Solution: Verify cluster is active
Check: Qdrant Cloud Dashboard → Clusters
```

**Hugging Face 503 Error:**
```
Solution: Model is loading (cold start)
Action: Test will retry automatically
```

---

## 📈 Continuous Integration

### GitHub Actions Example

Create `.github/workflows/api-tests.yml`:

```yaml
name: API Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run API tests
      env:
        SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
        SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        QDRANT_API_URL: ${{ secrets.QDRANT_API_URL }}
        QDRANT_API_KEY: ${{ secrets.QDRANT_API_KEY }}
        HUGGING_FACE_API_KEY: ${{ secrets.HUGGING_FACE_API_KEY }}
      run: ./run_tests.sh
```

---

## 🔐 Security Notes

**⚠️  NEVER commit API keys to version control!**

### Protected Files:
- `.env` (in .gitignore)
- Any file with credentials

### Safe Practices:
1. Use environment variables
2. Rotate keys regularly
3. Use separate keys for testing
4. Monitor API usage dashboards

---

## 📝 Adding New Tests

### Test Template

```dart
test('Your test name', () async {
  // Setup
  final url = 'https://api.example.com';
  
  try {
    // Execute
    final response = await http.get(Uri.parse(url));
    
    // Assert
    expect(response.statusCode, equals(200));
    print('✅ Your test passed');
  } catch (e) {
    fail('❌ Your test failed: $e');
  }
});
```

### Guidelines:
1. Use descriptive test names
2. Print success messages with ✅
3. Handle errors gracefully
4. Add timeouts for slow APIs
5. Clean up test data

---

## 📊 Test Metrics

**Code Coverage Target:** 80%
**Test Execution Time:** ~60 seconds
**Success Rate:** 95%+ (allowing for network issues)
**Flaky Tests:** < 5%

---

## 🤝 Contributing

When adding new APIs:

1. Add test to appropriate group
2. Update this README
3. Add API key to `.env.example`
4. Document common issues
5. Set performance benchmarks

---

## 📞 Support

**Issues with Tests?**
- Check test output for specific errors
- Review troubleshooting section
- Verify API credentials
- Check API status pages

**API Status Pages:**
- Supabase: https://status.supabase.com/
- Google Cloud: https://status.cloud.google.com/
- Qdrant: https://qdrant.tech/
- Hugging Face: https://status.huggingface.co/

---

## ✅ Checklist for Production

Before deploying:

- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] API keys secured
- [ ] Error handling implemented
- [ ] Rate limits configured
- [ ] Monitoring setup
- [ ] Backup APIs configured

---

**Last Updated:** November 2025  
**Test Suite Version:** 1.0.0  
**Total Tests:** 20

