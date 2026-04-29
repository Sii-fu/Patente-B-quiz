import 'package:flutter/material.dart';

import '../../../../models/homework_set.dart';
import 'homework_status_badge.dart';

class AdminHomeworkCard extends StatelessWidget {
  const AdminHomeworkCard({
    super.key,
    required this.homework,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onResults,
    required this.onLeaderboard,
  });

  final HomeworkSet homework;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onResults;
  final VoidCallback onLeaderboard;

  String _dateOrDash(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                HomeworkStatusBadge(lifecycle: homework.lifecycle),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                Text('Quizzes: ${homework.questionCount ?? 0}'),
                Text('Time: ${homework.timeLimitMinutes} min'),
                Text('Submissions: ${homework.submissionCount}'),
              ],
            ),
            const SizedBox(height: 6),
            Text('Start: ${_dateOrDash(homework.startsAt)}'),
            Text('End: ${_dateOrDash(homework.endsAt)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onView, child: const Text('View')),
                OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                OutlinedButton(onPressed: onResults, child: const Text('Results')),
                OutlinedButton(
                  onPressed: onLeaderboard,
                  child: const Text('Leaderboard'),
                ),
                OutlinedButton(onPressed: onDelete, child: const Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
