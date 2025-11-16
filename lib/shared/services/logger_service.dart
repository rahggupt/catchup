import 'package:flutter/foundation.dart';

/// Global logger service to capture all app logs and errors
/// Logs are stored in memory and can be downloaded as txt file
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Store logs in memory (max 1000 entries to prevent memory issues)
  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000;

  /// Log levels
  static const String levelInfo = 'INFO';
  static const String levelWarning = 'WARNING';
  static const String levelError = 'ERROR';
  static const String levelDebug = 'DEBUG';
  static const String levelSuccess = 'SUCCESS';

  /// Add a log entry
  void log(String message, {
    String level = levelInfo,
    String? category,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category ?? 'General',
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    // Add to list (keep only last 1000)
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Also print to console in debug mode
    if (kDebugMode) {
      final emoji = _getEmojiForLevel(level);
      print('$emoji [${entry.category}] $message');
      if (error != null) {
        print('   Error: $error');
      }
      if (stackTrace != null) {
        print('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n   ')}');
      }
    }
  }

  /// Convenience methods for different log levels
  void info(String message, {String? category}) {
    log(message, level: levelInfo, category: category);
  }

  void warning(String message, {String? category}) {
    log(message, level: levelWarning, category: category);
  }

  void error(String message, {String? category, dynamic error, StackTrace? stackTrace}) {
    log(message, level: levelError, category: category, error: error, stackTrace: stackTrace);
  }

  void debug(String message, {String? category}) {
    log(message, level: levelDebug, category: category);
  }

  void success(String message, {String? category}) {
    log(message, level: levelSuccess, category: category);
  }

  /// Get all logs
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(String level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs filtered by category
  List<LogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }

  /// Get logs filtered by time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Export logs as formatted string
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('='.repeat(80));
    buffer.writeln('CatchUp App Debug Logs');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${_logs.length}');
    buffer.writeln('='.repeat(80));
    buffer.writeln();

    for (final log in _logs) {
      buffer.writeln('-'.repeat(80));
      buffer.writeln('[${log.timestamp.toIso8601String()}] [${log.level}] [${log.category}]');
      buffer.writeln(log.message);
      
      if (log.error != null) {
        buffer.writeln('ERROR: ${log.error}');
      }
      
      if (log.stackTrace != null) {
        buffer.writeln('STACK TRACE:');
        buffer.writeln(log.stackTrace);
      }
      buffer.writeln();
    }

    buffer.writeln('='.repeat(80));
    buffer.writeln('End of Log');
    buffer.writeln('='.repeat(80));

    return buffer.toString();
  }

  /// Get log summary (counts by level)
  Map<String, int> getLogSummary() {
    final summary = <String, int>{
      levelInfo: 0,
      levelWarning: 0,
      levelError: 0,
      levelDebug: 0,
      levelSuccess: 0,
    };

    for (final log in _logs) {
      summary[log.level] = (summary[log.level] ?? 0) + 1;
    }

    return summary;
  }

  /// Get emoji for log level
  String _getEmojiForLevel(String level) {
    switch (level) {
      case levelInfo:
        return 'ℹ️';
      case levelWarning:
        return '⚠️';
      case levelError:
        return '❌';
      case levelDebug:
        return '🔍';
      case levelSuccess:
        return '✅';
      default:
        return '📝';
    }
  }
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String category;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// Format as human-readable string
  String format() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toLocal().toString().substring(0, 19)}] ');
    buffer.write('[$level] ');
    buffer.write('[$category] ');
    buffer.write(message);
    
    if (error != null) {
      buffer.write('\n   Error: $error');
    }
    
    return buffer.toString();
  }
}

/// String extension for repeat
extension on String {
  String repeat(int count) => List.filled(count, this).join();
}

