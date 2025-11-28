/// Utility class to format error messages for user-friendly display
class ErrorMessageFormatter {
  /// Format an error for display to the user
  /// Converts technical error messages to user-friendly text
  static String format(dynamic error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('invalid login') ||
        errorString.contains('invalid credentials')) {
      return 'Authentication failed. Please check your credentials.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Database errors
    if (errorString.contains('duplicate') ||
        errorString.contains('unique constraint')) {
      return 'This item already exists.';
    }

    if (errorString.contains('not found') ||
        errorString.contains('no record')) {
      return 'Item not found.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('server error') ||
        errorString.contains('internal error')) {
      return 'Server error. Please try again later.';
    }

    // Rate limit errors
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Format errors
    if (errorString.contains('format') ||
        errorString.contains('invalid') ||
        errorString.contains('malformed')) {
      return 'Invalid format. Please check your input.';
    }

    // Storage errors
    if (errorString.contains('storage') ||
        errorString.contains('disk') ||
        errorString.contains('space')) {
      return 'Storage error. Please free up some space.';
    }

    // If error contains "Exception:", extract the message after it
    if (errorString.contains('exception:')) {
      final parts = errorString.split('exception:');
      if (parts.length > 1) {
        final message = parts[1].trim();
        // If the extracted message looks user-friendly (no stack traces), use it
        if (!message.contains('at ') &&
            !message.contains('stack') &&
            message.length < 100) {
          return message[0].toUpperCase() + message.substring(1);
        }
      }
    }

    // Default friendly message
    return 'Something went wrong. Please try again.';
  }

  /// Format an error with a custom prefix
  static String formatWithPrefix(dynamic error, String prefix) {
    final message = format(error);
    return '$prefix: $message';
  }

  /// Check if an error is network-related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup');
  }
}



