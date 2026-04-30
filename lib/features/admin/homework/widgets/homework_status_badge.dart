import 'package:flutter/material.dart';

import '../../../../models/homework_set.dart';

class HomeworkStatusBadge extends StatelessWidget {
  const HomeworkStatusBadge({
    super.key,
    required this.lifecycle,
  });

  final HomeworkLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (lifecycle) {
      case HomeworkLifecycle.draft:
        label = 'Draft';
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case HomeworkLifecycle.upcoming:
        label = 'Scheduled';
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        break;
      case HomeworkLifecycle.active:
        label = 'Active';
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        break;
      case HomeworkLifecycle.completed:
        label = 'Completed';
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
