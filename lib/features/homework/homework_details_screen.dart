import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/homework_score.dart';
import '../../models/homework_set.dart';
import '../../models/quiz_session.dart';
import '../../repositories/homework_repository.dart';
import '../quiz/quiz_screen.dart';
import 'homework_leaderboard_screen.dart';
import 'homework_localizations.dart';
import 'homework_result_screen.dart';

class HomeworkDetailsScreen extends StatefulWidget {
  const HomeworkDetailsScreen({
    super.key,
    required this.initialHomework,
    this.initialScore,
  });

  final HomeworkSet initialHomework;
  final HomeworkScore? initialScore;

  @override
  State<HomeworkDetailsScreen> createState() => _HomeworkDetailsScreenState();
}

class _HomeworkDetailsScreenState extends State<HomeworkDetailsScreen> {
  final HomeworkRepository _repository = HomeworkRepository();

  late HomeworkSet _homework;
  HomeworkScore? _score;
  bool _isLoading = false;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _homework = widget.initialHomework;
    _score = widget.initialScore;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final fetchedHomework = await _repository.getHomeworkSetById(_homework.id);
      final fetchedScore = await _repository.getCurrentUserHomeworkScore(_homework.id);
      if (!mounted) return;
      setState(() {
        if (fetchedHomework != null) {
          _homework = fetchedHomework;
        }
        _score = fetchedScore;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  _DetailsStatus _currentStatus() {
    if (_score != null) return _DetailsStatus.completed;

    final now = DateTime.now().toUtc();
    final startsAt = _homework.startsAt?.toUtc();
    final endsAt = _homework.endsAt?.toUtc();

    if (startsAt != null && now.isBefore(startsAt)) {
      return _DetailsStatus.upcoming;
    }
    if (endsAt != null && now.isAfter(endsAt)) {
      return _DetailsStatus.completed;
    }
    return _DetailsStatus.active;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _startHomework({required bool retry}) async {
    if (_isStarting) return;
    final l10n = AppLocalizations.of(context)!;

    final hasSubmission = _score != null;
    if (hasSubmission && !retry) return;
    if (hasSubmission && !_homework.retryAllowed) return;

    if (!hasSubmission && !_homework.retryAllowed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.homeworkStartWarningTitle),
          content: Text(l10n.homeworkStartWarningMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.profileCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.homeworkStart),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isStarting = true);
    try {
      final questions = await _repository.getPreparedHomeworkQuestions(_homework);
      if (!mounted) return;
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quizNoQuestions)),
        );
        setState(() => _isStarting = false);
        return;
      }

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            isExamMode: true,
            quizMode: QuizMode.simulation,
            isHomeworkMode: true,
            homeworkSet: _homework,
            homeworkQuestions: questions,
            homeworkTimeLimitMinutes: _homework.timeLimitMinutes,
          ),
        ),
      );
      if (!mounted) return;
      await _refresh();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.homeworkFailedToStart}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _openLeaderboard() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkLeaderboardScreen(homework: _homework),
      ),
    );
  }

  Future<void> _openResult() async {
    if (_score == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkResultScreen(
          homework: _homework,
          score: _score!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = _currentStatus();
    final isCompleted = status == _DetailsStatus.completed;
    final hasSubmission = _score != null;

    String statusText;
    switch (status) {
      case _DetailsStatus.active:
        statusText = l10n.homeworkActiveNow;
        break;
      case _DetailsStatus.upcoming:
        statusText = l10n.homeworkUpcoming;
        break;
      case _DetailsStatus.completed:
        statusText = l10n.homeworkCompleted;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeworkViewDetails),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _homework.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((_homework.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_homework.description!.trim()),
                ],
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.homeworkQuestionCount}: ${_homework.questionCount ?? 0}'),
                        const SizedBox(height: 6),
                        Text('${l10n.homeworkTimeLimit}: ${_homework.timeLimitMinutes} min'),
                        const SizedBox(height: 6),
                        Text('${l10n.homeworkStartDate}: ${_formatDateTime(_homework.startsAt)}'),
                        const SizedBox(height: 6),
                        Text('${l10n.homeworkEndDate}: ${_formatDateTime(_homework.endsAt)}'),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.homeworkRetryAllowed}: ${_homework.retryAllowed ? l10n.homeworkYes : l10n.homeworkNo}',
                        ),
                        const SizedBox(height: 6),
                        Text('${l10n.homeworkStatus}: $statusText'),
                        if (_score != null) ...[
                          const SizedBox(height: 6),
                          Text('${l10n.resultScore}: ${_score!.scorePercentage}%'),
                          const SizedBox(height: 6),
                          Text(
                            '${l10n.resultCorrect}: ${_score!.correctAnswers} • ${l10n.resultErrors}: ${_score!.wrongAnswers}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${l10n.homeworkSubmitted}: ${_formatDateTime(_score!.submittedAt)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (status == _DetailsStatus.upcoming)
                  FilledButton.tonal(
                    onPressed: null,
                    child: Text(l10n.homeworkStartLabel),
                  ),
                if (status == _DetailsStatus.active && !hasSubmission)
                  FilledButton(
                    onPressed: _isStarting ? null : () => _startHomework(retry: false),
                    child: Text(l10n.homeworkStartLabel),
                  ),
                if (isCompleted && hasSubmission) ...[
                  FilledButton.tonal(
                    onPressed: _openResult,
                    child: Text(l10n.homeworkViewResult),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _openLeaderboard,
                    child: Text(l10n.homeworkLeaderboard),
                  ),
                  if (_homework.retryAllowed) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _isStarting ? null : () => _startHomework(retry: true),
                      child: Text(l10n.homeworkRetry),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

enum _DetailsStatus { active, upcoming, completed }
