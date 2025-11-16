# 🐛 Debug Logging System Guide

## Overview

A comprehensive debug logging system has been implemented to help diagnose issues in production builds. The system captures all app logs, errors, and diagnostics in memory and allows you to view, filter, and export them.

---

## 🎯 Features

✅ **Capture all app logs and errors**  
✅ **Flag-based visibility** (only shows in DEBUG_MODE)  
✅ **Beautiful UI** with filtering by level and category  
✅ **Download logs** as txt file to phone  
✅ **Share logs** via any app  
✅ **Log summary** with counts by level  
✅ **Expandable log entries** with full error details and stack traces  
✅ **Memory-efficient** (keeps last 1000 logs)  

---

## 🚀 How to Enable Debug Mode

### For Development (Flutter Run)

```bash
flutter run --dart-define=DEBUG_MODE=true
```

### For Production APK Build

```bash
flutter build apk --dart-define=DEBUG_MODE=true
```

### For Release APK Build

```bash
flutter build apk --release --dart-define=DEBUG_MODE=true
```

---

## 📱 How to Access Debug Logs

1. Open the app
2. Go to **Profile** tab
3. Scroll down to see **"Debug Settings"** section (only visible if DEBUG_MODE=true)
4. Tap **"View Debug Logs"**
5. You'll see all captured logs

---

## 🎨 Debug Logs Screen Features

### Summary Cards
- **Info** count (blue)
- **Warning** count (orange)
- **Error** count (red)
- **Debug** count (purple)

### Filters
- **Level**: All, INFO, WARNING, ERROR, DEBUG, SUCCESS
- **Category**: All, Auth, Feed, Collections, AI, Database, etc.

### Actions
- **Download** 📥: Save logs as txt file to phone
- **Share** 📤: Share logs via email, messaging, etc.
- **Clear** 🗑️: Delete all logs

### Log Entry Details
- Tap any log to expand and see:
  - Full message
  - Error details (if any)
  - Stack trace (if any)
  - Copy button to copy individual log

---

## 💻 How to Add Logging to Your Code

### 1. Import the LoggerService

```dart
import '../../../../shared/services/logger_service.dart';
```

### 2. Create Logger Instance

```dart
class MyService {
  final LoggerService _logger = LoggerService();
  
  // Your code here
}
```

### 3. Use Logging Methods

#### Info Log (General information)
```dart
_logger.info('User viewed profile screen', category: 'UI');
```

#### Success Log (Operation succeeded)
```dart
_logger.success('Article saved to collection', category: 'Collections');
```

#### Warning Log (Non-critical issues)
```dart
_logger.warning('API rate limit approaching', category: 'API');
```

#### Error Log (Errors with optional stack trace)
```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  _logger.error(
    'Failed to save article', 
    category: 'Collections',
    error: e,
    stackTrace: stackTrace
  );
}
```

#### Debug Log (Development info)
```dart
_logger.debug('Cache hit for article ID: $id', category: 'Cache');
```

---

## 📂 Recommended Categories

Use these standard categories for consistency:

- **Auth**: Login, signup, password reset
- **Feed**: Article loading, RSS parsing
- **Collections**: Create, update, delete collections
- **AI**: Chat, RAG, embeddings
- **Database**: Supabase operations
- **API**: External API calls
- **UI**: Screen navigation, user interactions
- **Cache**: Caching operations
- **Network**: Network requests/responses

---

## 🔍 Log Levels Guide

### INFO (Blue)
- General informational messages
- User actions (e.g., "User tapped save button")
- State changes (e.g., "Feed loaded successfully")

### WARNING (Orange)
- Non-critical issues
- Deprecated feature usage
- Rate limit warnings
- Slow operations

### ERROR (Red)
- Operation failures
- Exceptions caught
- API errors
- Database errors

### DEBUG (Purple)
- Development/diagnostic info
- Cache hits/misses
- Performance metrics
- Internal state

### SUCCESS (Green)
- Successful operations
- Confirmations
- Completion messages

---

## 📊 Example Integration

### auth_provider.dart (Already Integrated)

```dart
// Login example
try {
  _logger.info('Attempting login for: $email', category: 'Auth');
  
  final response = await SupabaseConfig.client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  
  _logger.success('Login successful for: $email', category: 'Auth');
  return response;
} catch (e, stackTrace) {
  _logger.error(
    'Login failed for: $email', 
    category: 'Auth', 
    error: e, 
    stackTrace: stackTrace
  );
  rethrow;
}
```

### How to Add to Other Files

#### collections_provider.dart
```dart
import '../../../../shared/services/logger_service.dart';

class CollectionsProvider {
  final LoggerService _logger = LoggerService();
  
  Future<void> createCollection(String name) async {
    _logger.info('Creating collection: $name', category: 'Collections');
    try {
      // ... your code ...
      _logger.success('Collection created: $name', category: 'Collections');
    } catch (e, stackTrace) {
      _logger.error('Failed to create collection', 
        category: 'Collections', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

#### ai_service.dart
```dart
import '../../services/logger_service.dart';

class AIService {
  final LoggerService _logger = LoggerService();
  
  Future<String> getChatResponse(String query) async {
    _logger.info('Processing AI query', category: 'AI');
    _logger.debug('Query length: ${query.length} chars', category: 'AI');
    
    try {
      final response = await _callGeminiAPI(query);
      _logger.success('AI response generated', category: 'AI');
      return response;
    } catch (e, stackTrace) {
      _logger.error('AI request failed', 
        category: 'AI', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

---

## 📥 Downloaded Log File Format

```
================================================================================
CatchUp App Debug Logs
Generated: 2025-11-16T10:27:35.123Z
Total Entries: 152
================================================================================

--------------------------------------------------------------------------------
[2025-11-16T10:25:12.456Z] [INFO] [Auth]
Attempting login for: user@example.com

--------------------------------------------------------------------------------
[2025-11-16T10:25:13.789Z] [SUCCESS] [Auth]
Login successful for: user@example.com

--------------------------------------------------------------------------------
[2025-11-16T10:25:20.123Z] [ERROR] [Collections]
Failed to create collection
ERROR: PostgrestException(message: infinite recursion detected)
STACK TRACE:
#0      CollectionsService.createCollection
#1      CollectionsProvider.createNewCollection
...

================================================================================
End of Log
================================================================================
```

---

## 🧪 Testing the Debug System

### 1. Enable Debug Mode

```bash
flutter run --dart-define=DEBUG_MODE=true
```

### 2. Test Log Capture

- Perform various actions in the app (login, create collection, etc.)
- Errors will be automatically logged

### 3. View Logs

- Go to Profile > Debug Settings > View Debug Logs
- Verify logs are appearing

### 4. Test Filtering

- Filter by level (ERROR, WARNING, etc.)
- Filter by category (Auth, Collections, etc.)

### 5. Test Download

- Tap download icon
- Check if file is saved
- Verify file content

### 6. Test Share

- Tap share icon
- Share via email or messaging app
- Verify recipient can read the logs

---

## 🎯 Best Practices

### 1. Log Important Events
```dart
✅ DO: _logger.info('User saved article to MyCollection', category: 'Collections');
❌ DON'T: Over-log trivial events like "Button tapped"
```

### 2. Always Log Errors
```dart
✅ DO: Log all caught exceptions with stack traces
❌ DON'T: Silently swallow errors
```

### 3. Use Meaningful Messages
```dart
✅ DO: _logger.error('Failed to parse RSS feed from $url', category: 'Feed');
❌ DON'T: _logger.error('Error', category: 'Feed');
```

### 4. Include Context
```dart
✅ DO: _logger.info('Creating collection "$name" for user $userId', category: 'Collections');
❌ DON'T: _logger.info('Creating collection', category: 'Collections');
```

### 5. Don't Log Sensitive Data
```dart
❌ DON'T: _logger.info('Password: $password'); // NEVER log passwords
❌ DON'T: _logger.info('API Key: $apiKey'); // NEVER log secrets
✅ DO: _logger.info('API key length: ${apiKey.length} chars');
```

---

## 🔧 Troubleshooting

### Debug Section Not Showing

```bash
# Make sure you built with DEBUG_MODE=true
flutter build apk --dart-define=DEBUG_MODE=true

# For flutter run:
flutter run --dart-define=DEBUG_MODE=true
```

### Logs Not Appearing

1. Check if LoggerService is imported
2. Check if logger instance is created
3. Verify logging methods are called
4. Check console output (logs also print to console in debug mode)

### Download/Share Not Working

1. Make sure `path_provider` package is installed
2. Check file permissions (Android: WRITE_EXTERNAL_STORAGE)
3. Check if app has storage permission

---

## 📱 Building APK with Debug Mode

### Development Build (with debug logs)

```bash
flutter build apk --dart-define=DEBUG_MODE=true
```

### Production Build (without debug logs)

```bash
flutter build apk --release
# Debug section will NOT appear (DEBUG_MODE defaults to false)
```

### Test Both Versions

1. Build with DEBUG_MODE=true
   - Verify debug section appears
   - Test log capture and download

2. Build with DEBUG_MODE=false (or omit)
   - Verify debug section is hidden
   - Confirm no performance impact

---

## 🎉 Summary

The debug logging system is now ready to use!

**To enable:**
```bash
flutter run --dart-define=DEBUG_MODE=true
```

**To access:**
Profile → Debug Settings → View Debug Logs

**To add logging:**
```dart
final LoggerService _logger = LoggerService();
_logger.info('Your message', category: 'YourCategory');
```

Happy debugging! 🐛🔍

