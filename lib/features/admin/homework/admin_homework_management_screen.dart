import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/homework_set.dart';
import '../../../models/homework_score.dart';
import '../../../repositories/homework_repository.dart';
import 'admin_homework_create_screen.dart';
import 'widgets/admin_homework_card.dart';

class AdminHomeworkManagementScreen extends StatefulWidget {
  const AdminHomeworkManagementScreen({super.key});

  @override
  State<AdminHomeworkManagementScreen> createState() =>
      _AdminHomeworkManagementScreenState();
}

class _AdminHomeworkManagementScreenState
    extends State<AdminHomeworkManagementScreen> {
  final HomeworkRepository _repository = HomeworkRepository();

  List<HomeworkSet> _scheduled = <HomeworkSet>[];
  List<HomeworkSet> _active = <HomeworkSet>[];
  List<HomeworkSet> _completed = <HomeworkSet>[];
  bool _isLoading = true;

  int _totalSubmissions = 0;
  int _totalQuizzesAssigned = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _repository.getHomeworkSets();
    final enriched = await Future.wait(all.map(_repository.enrichHomeworkStats));

    final scheduled = enriched
        .where(
          (h) =>
              h.lifecycle == HomeworkLifecycle.upcoming ||
              h.lifecycle == HomeworkLifecycle.draft,
        )
        .toList();
    final active = enriched.where((h) => h.lifecycle == HomeworkLifecycle.active).toList();
    final completed =
        enriched.where((h) => h.lifecycle == HomeworkLifecycle.completed).toList();

    scheduled.sort((a, b) {
      final ad = a.startsAt ?? a.createdAt;
      final bd = b.startsAt ?? b.createdAt;
      return ad.compareTo(bd);
    });
    active.sort((a, b) {
      final ad = a.startsAt ?? a.createdAt;
      final bd = b.startsAt ?? b.createdAt;
      return bd.compareTo(ad);
    });
    completed.sort((a, b) {
      final ad = a.endsAt ?? a.createdAt;
      final bd = b.endsAt ?? b.createdAt;
      return bd.compareTo(ad);
    });

    final totalSubmissions =
        enriched.fold<int>(0, (acc, h) => acc + h.submissionCount);
    final totalQuizzes =
        enriched.fold<int>(0, (acc, h) => acc + (h.questionCount ?? 0));

    if (!mounted) return;
    setState(() {
      _scheduled = scheduled;
      _active = active;
      _completed = completed;
      _totalSubmissions = totalSubmissions;
      _totalQuizzesAssigned = totalQuizzes;
      _isLoading = false;
    });
  }

  Future<void> _openCreate({HomeworkSet? edit}) async {
    HapticFeedback.mediumImpact();
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminHomeworkCreateScreen(editingHomework: edit),
      ),
    );
    if (changed == true && mounted) {
      _load();
    }
  }

  Future<void> _deleteHomework(HomeworkSet homework) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homework'),
        content: Text('Delete "${homework.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _repository.deleteHomework(homework.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Homework deleted.' : 'Failed to delete homework.'),
      ),
    );
    if (success) {
      _load();
    }
  }

  Future<void> _showHomeworkDetails(HomeworkSet homework) async {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(homework.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quizzes: ${homework.questionCount ?? 0}'),
            Text('Time limit: ${homework.timeLimitMinutes} min'),
            Text('Start: ${homework.startsAt?.toLocal() ?? '-'}'),
            Text('End: ${homework.endsAt?.toLocal() ?? '-'}'),
            Text('Submissions: ${homework.submissionCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResults(HomeworkSet homework) async {
    final scores = await _repository.getHomeworkScores(homework.id);
    if (!mounted) return;

    final attempts = scores.length;
    final average = attempts == 0
        ? 0.0
        : scores.map((s) => s.scorePercentage).reduce((a, b) => a + b) / attempts;
    final best = attempts == 0
        ? null
        : scores.map((s) => s.scorePercentage).reduce((a, b) => a > b ? a : b);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Results • ${homework.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attempts: $attempts'),
            Text('Average score: ${average.toStringAsFixed(1)}%'),
            Text('Best score: ${best?.toStringAsFixed(0) ?? '-'}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaderboard(HomeworkSet homework) async {
    final scores = await _repository.getHomeworkScores(homework.id);
    if (!mounted) return;

    final sorted = List<HomeworkScore>.from(scores)
      ..sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));
    final top = sorted.take(20).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leaderboard • ${homework.title}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: top.isEmpty
                    ? const Center(child: Text('No submissions yet.'))
                    : ListView.builder(
                        itemCount: top.length,
                        itemBuilder: (context, index) {
                          final item = top[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text('User: ${item.userId.substring(0, 8)}...'),
                            subtitle: Text(
                              'Correct: ${item.correctAnswers} / ${item.totalQuestions}',
                            ),
                            trailing: Text('${item.scorePercentage}%'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    final totalHomeworks = _scheduled.length + _active.length + _completed.length;
    final averageSubmissions =
        totalHomeworks == 0 ? 0.0 : _totalSubmissions / totalHomeworks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Homework Analytics',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'Total Homeworks', value: '$totalHomeworks'),
                _MetricChip(label: 'Total Submissions', value: '$_totalSubmissions'),
                _MetricChip(label: 'Total Quizzes Assigned', value: '$_totalQuizzesAssigned'),
                _MetricChip(
                  label: 'Avg Submissions/Homework',
                  value: averageSubmissions.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<HomeworkSet> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${items.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No homework in this section.'),
              )
            else
              ...items.map(
                (item) => AdminHomeworkCard(
                  homework: item,
                  onView: () => _showHomeworkDetails(item),
                  onEdit: () => _openCreate(edit: item),
                  onDelete: () => _deleteHomework(item),
                  onResults: () => _showResults(item),
                  onLeaderboard: () => _showLeaderboard(item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(),
        icon: const Icon(Icons.add),
        label: const Text('Create Homework'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  _buildAnalyticsSummary(),
                  _buildSection('Scheduled Homeworks', _scheduled),
                  _buildSection('Active Homeworks', _active),
                  _buildSection('Completed Homeworks', _completed),
                ],
              ),
            ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
