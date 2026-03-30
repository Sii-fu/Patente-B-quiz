import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/retry_helper.dart';

/// Error boundary widget for graceful error handling
/// Displays user-friendly error messages with retry functionality
class ErrorBoundary extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? customMessage;
  final IconData? icon;
  final bool showDetails;

  const ErrorBoundary({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.icon,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorCategory = error.category;
    final userMessage = customMessage ?? error.getUserMessage();
    
    // Choose icon based on error category
    final displayIcon = icon ?? _getIconForCategory(errorCategory);
    final iconColor = _getColorForCategory(errorCategory, theme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              displayIcon,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            
            // User-friendly message
            Text(
              userMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Technical details (collapsible)
            if (showDetails) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical Details:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Icons.wifi_off_rounded;
      case ErrorCategory.server:
        return Icons.cloud_off_rounded;
      case ErrorCategory.client:
        return Icons.error_outline_rounded;
      case ErrorCategory.database:
        return Icons.storage_rounded;
      case ErrorCategory.timeout:
        return Icons.timer_off_rounded;
      case ErrorCategory.unknown:
        return Icons.help_outline_rounded;
    }
  }

  Color _getColorForCategory(ErrorCategory category, ThemeData theme) {
    switch (category) {
      case ErrorCategory.network:
        return Colors.orange;
      case ErrorCategory.server:
        return Colors.red;
      case ErrorCategory.client:
        return theme.colorScheme.error;
      case ErrorCategory.database:
        return Colors.purple;
      case ErrorCategory.timeout:
        return Colors.amber;
      case ErrorCategory.unknown:
        return theme.colorScheme.secondary;
    }
  }
}

/// Compact error widget for inline error display
class CompactErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const CompactErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.getUserMessage(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: theme.colorScheme.primary,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}

/// Snackbar helper for showing error messages
class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String error,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final userMessage = error.getUserMessage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(userMessage),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
