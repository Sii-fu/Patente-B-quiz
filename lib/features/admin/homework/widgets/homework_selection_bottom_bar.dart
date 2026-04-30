import 'package:flutter/material.dart';

class HomeworkSelectionBottomBar extends StatelessWidget {
  const HomeworkSelectionBottomBar({
    super.key,
    required this.onViewSelected,
    required this.onClearAll,
    required this.onContinue,
    required this.selectedCount,
  });

  final VoidCallback onViewSelected;
  final VoidCallback onClearAll;
  final VoidCallback onContinue;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewSelected,
                icon: const Icon(Icons.shopping_basket_outlined),
                label: Text('Selected ($selectedCount)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
