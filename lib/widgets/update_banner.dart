import 'package:flutter/material.dart';
import '../services/cache_version_manager.dart';
import '../utils/theme.dart';

/// Banner widget to notify users about available content updates
class UpdateAvailableBanner extends StatelessWidget {
  final CacheUpdateCheck updateCheck;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateAvailableBanner({
    super.key,
    required this.updateCheck,
    required this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!updateCheck.isStale) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Content Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update to v${updateCheck.serverVersion}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Update button
            TextButton(
              onPressed: onUpdate,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            
            // Dismiss button
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                color: Colors.white.withOpacity(0.8),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact update indicator for app bar
class UpdateIndicator extends StatelessWidget {
  final VoidCallback onTap;

  const UpdateIndicator({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.system_update,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Update',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for showing update details
class UpdateDialog extends StatelessWidget {
  final CacheUpdateCheck updateCheck;
  final VoidCallback onUpdate;

  const UpdateDialog({
    super.key,
    required this.updateCheck,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.system_update,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version of content is available.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Current Version',
            'v${updateCheck.localVersion}',
            theme,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'New Version',
            'v${updateCheck.serverVersion}',
            theme,
            highlight: true,
          ),
          if (updateCheck.cacheAgeDays >= 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Cache Age',
              '${updateCheck.cacheAgeDays} days',
              theme,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onUpdate();
          },
          icon: const Icon(Icons.download),
          label: const Text('Update Now'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required CacheUpdateCheck updateCheck,
    required VoidCallback onUpdate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        updateCheck: updateCheck,
        onUpdate: onUpdate,
      ),
    );
  }
}
