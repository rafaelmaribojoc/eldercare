import 'dart:io';

class ErrorHandler {
  /// Transforms raw exceptions into readable, friendly messages.
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    final errorStr = error.toString().toLowerCase();

    // 1. Network / Internet Connection Errors
    if (_isNetworkErrorString(errorStr) || error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'The connection timed out. Please check your internet and try again.';
    }

    if (errorStr.contains('connection refused') ||
        errorStr.contains('connection reset')) {
      return 'Could not connect to the server. It may be under maintenance.';
    }

    if (errorStr.contains('handshake') || errorStr.contains('certificate')) {
      return 'A secure connection could not be established. Please try again later.';
    }

    // 2. Supabase / Database Common Errors
    if (errorStr.contains('postgrestexception')) {
      if (errorStr.contains('duplicate key value')) {
        return 'This record already exists. Please use different details.';
      }
      if (errorStr.contains('violates foreign key')) {
        return 'This action cannot be completed because related records still exist.';
      }
      return 'A database error occurred. Please refresh and try again.';
    }

    if (errorStr.contains('authexception')) {
      if (errorStr.contains('invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (errorStr.contains('email not confirmed')) {
        return 'Your email address has not been confirmed. Please check your inbox.';
      }
      return 'Authentication failed. Please check your credentials.';
    }

    // 3. Storage / File Errors
    if (errorStr.contains('storageexception') ||
        errorStr.contains('storage error')) {
      return 'Failed to process file. Please try again.';
    }

    if (errorStr.contains('platform_version') ||
        errorStr.contains('unsupported operation')) {
      return 'This feature is not supported on your device.';
    }

    // 4. Fallback — strip "Exception:" prefix and return clean message
    final cleanError = error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('exception: ', '')
        .trim();

    // If the cleaned message still looks technical (contains URLs, stack traces),
    // return a generic friendly message
    if (_looksLikeTechnicalError(cleanError)) {
      return 'Something went wrong. Please check your connection and try again.';
    }

    if (cleanError.isNotEmpty) {
      return cleanError;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Evaluates if the error is specifically related to being offline.
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    if (error is SocketException) return true;
    final errorStr = error.toString().toLowerCase();
    return _isNetworkErrorString(errorStr);
  }

  static bool _isNetworkErrorString(String errorStr) {
    return errorStr.contains('socketexception') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('failed to fetch') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('no internet connection') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('xmlhttprequest error') ||
        errorStr.contains('networkerror') ||
        errorStr.contains('err_internet_disconnected') ||
        errorStr.contains('err_network_changed') ||
        errorStr.contains('os error 7') ||
        errorStr.contains('os error 101') ||
        errorStr.contains('os error 110') ||
        errorStr.contains('os error 111');
  }

  /// Checks if a message looks like a technical error (URLs, stack traces, etc.)
  static bool _looksLikeTechnicalError(String message) {
    return message.contains('http://') ||
        message.contains('https://') ||
        message.contains('supabase') ||
        message.contains('rest/v1/') ||
        message.contains('dart:') ||
        message.contains('.dart:') ||
        message.contains('stack trace') ||
        message.contains('postgrest') ||
        message.length > 200;
  }
}
