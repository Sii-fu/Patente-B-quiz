import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/theme.dart';

import 'providers/homework_builder_provider.dart';

class AdminHomeworkSelectedScreen extends StatelessWidget {
  const AdminHomeworkSelectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final builder = context.watch<HomeworkBuilderProvider>();
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Quizzes'),
      ),
      body: builder.selectedQuestions.isEmpty
          ? const Center(child: Text('No selected quizzes yet.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Manual: ${builder.manualSelectedCount} • Auto-filled: ${builder.autoFilledCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: builder.selectedQuestions.length,
                    onReorder: builder.reorderSelected,
                    itemBuilder: (context, index) {
                      final question = builder.selectedQuestions[index];
                      final isAuto = builder.isAutoFilledQuestion(question.id);
                      return Card(
                        key: ValueKey('selected-q-${question.id}'),
                        color: isAuto
                            ? Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withOpacity(0.35)
                            : null,
                        child: ListTile(
                          leading: const Icon(Icons.drag_handle),
                          title: Text(
                            question.getText(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const TextSpan(text: 'Answer: '),
                                TextSpan(
                                  text: question.isTrue ? 'Vero' : 'Falso',
                                  style: TextStyle(
                                    color: question.isTrue
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: isAuto ? ' • Auto-added' : ' • Manual',
                                  style: TextStyle(
                                    color: isAuto
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                builder.removeSelectedQuestion(question.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: builder.selectedCount == 0
                      ? null
                      : () => builder.clearAllSelected(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: builder.autoFillRemaining,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto-fill Remaining'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
