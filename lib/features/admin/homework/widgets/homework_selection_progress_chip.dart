import 'package:flutter/material.dart';

class HomeworkSelectionProgressChip extends StatelessWidget {
  const HomeworkSelectionProgressChip({
    super.key,
    required this.selectedCount,
    required this.targetCount,
    required this.onEditTarget,
  });

  final int selectedCount;
  final int targetCount;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = selectedCount >= targetCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: reached
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Selected: $selectedCount / $targetCount',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: reached
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onEditTarget,
          tooltip: 'Edit target',
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}
