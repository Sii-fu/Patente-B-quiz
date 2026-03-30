import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Helper class for implementing retry logic with exponential backoff
/// Useful for handling transient network failures and API errors
class RetryHelper {
  /// Execute an operation with retry logic
  /// 
  /// [operation] - The async function to execute
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay in milliseconds (default: 500ms)
  /// [maxDelay] - Maximum delay between retries (default: 10 seconds)
  /// [shouldRetry] - Custom function to determine if error is retryable
  /// 
  /// Implements exponential backoff: 500ms, 1000ms, 2000ms, etc.
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (error, stackTrace) {
        // Check if we should retry this error
        final canRetry = shouldRetry?.call(error) ?? _isRetryableError(error);
        
        if (!canRetry || attempt >= maxAttempts) {
          // No more retries - rethrow the error
          debugPrint('❌ RetryHelper: Failed after $attempt attempts - $error');
          rethrow;
        }

        // Log retry attempt
        debugPrint('⚠️ RetryHelper: Attempt $attempt failed, retrying in ${currentDelay.inMilliseconds}ms - $error');
        
        // Wait before next retry
        await Future.delayed(currentDelay);
        
        // Exponential backoff: double the delay each time (capped at maxDelay)
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// Determine if an error is retryable (transient failure vs permanent error)
  static bool _isRetryableError(dynamic error) {
    // Network errors - usually transient
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;
    
    // Handle string errors from Supabase/APIs
    if (error is String) {
      final errorLower = error.toLowerCase();
      
      // Network-related errors
      if (errorLower.contains('network')) return true;
      if (errorLower.contains('timeout')) return true;
      if (errorLower.contains('connection')) return true;
      if (errorLower.contains('socket')) return true;
      
      // Server errors (5xx) - usually transient
      if (errorLower.contains('500')) return true;
      if (errorLower.contains('502')) return true;
      if (errorLower.contains('503')) return true;
      if (errorLower.contains('504')) return true;
      
      // Rate limiting - should retry
      if (errorLower.contains('rate limit')) return true;
      if (errorLower.contains('too many requests')) return true;
      
      // Don't retry client errors (4xx)
      if (errorLower.contains('400')) return false;
      if (errorLower.contains('401')) return false;
      if (errorLower.contains('403')) return false;
      if (errorLower.contains('404')) return false;
    }
    
    // Database errors - usually not transient
    if (error.toString().contains('DatabaseException')) return false;
    if (error.toString().contains('FormatException')) return false;
    
    // Default: retry for unknown errors (conservative approach)
    return true;
  }

  /// Quick retry for fast operations (2 attempts, 200ms delay)
  static Future<T> quickRetry<T>(Future<T> Function() operation) {
    return execute(
      operation: operation,
      maxAttempts: 2,
      initialDelay: const Duration(milliseconds: 200),
      maxDelay: const Duration(milliseconds: 500),
    );
  }

  /// Aggressive retry for critical operations (5 attempts, longer delays)
  static Future<T> aggressiveRetry<T>(Future<T> Function() operation) {
    return execute(
      operation: operation,
      maxAttempts: 5,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 30),
    );
  }
}

/// Error categories for better error handling
enum ErrorCategory {
  network,      // Network connectivity issues
  server,       // Server-side errors (5xx)
  client,       // Client errors (4xx, validation)
  database,     // Local database errors
  timeout,      // Operation timeout
  unknown,      // Unclassified errors
}

/// Extension to categorize errors
extension ErrorCategorization on Object {
  ErrorCategory get category {
    if (this is SocketException) return ErrorCategory.network;
    if (this is TimeoutException) return ErrorCategory.timeout;
    if (this is HttpException) return ErrorCategory.network;
    
    final errorString = toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return ErrorCategory.network;
    }
    
    if (errorString.contains('500') || 
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return ErrorCategory.server;
    }
    
    if (errorString.contains('400') || 
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404')) {
      return ErrorCategory.client;
    }
    
    if (errorString.contains('timeout')) {
      return ErrorCategory.timeout;
    }
    
    if (errorString.contains('database') || 
        errorString.contains('sqlite')) {
      return ErrorCategory.database;
    }
    
    return ErrorCategory.unknown;
  }
  
  /// Get user-friendly error message
  String getUserMessage() {
    switch (category) {
      case ErrorCategory.network:
        return 'No internet connection. Please check your network and try again.';
      case ErrorCategory.server:
        return 'Server is temporarily unavailable. Please try again later.';
      case ErrorCategory.client:
        return 'Invalid request. Please check your input.';
      case ErrorCategory.database:
        return 'Local database error. Try restarting the app.';
      case ErrorCategory.timeout:
        return 'Request timed out. Please try again.';
      case ErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
