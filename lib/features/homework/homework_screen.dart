import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../models/homework_score.dart';
import '../../models/homework_set.dart';
import '../../models/quiz_session.dart';
import '../../repositories/homework_repository.dart';
import '../quiz/quiz_screen.dart';
import 'homework_details_screen.dart';
import 'homework_leaderboard_screen.dart';
import 'homework_localizations.dart';
import 'homework_result_screen.dart';

enum _HomeworkTab { active, upcoming, completed }

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  final HomeworkRepository _repository = HomeworkRepository();

  late final TabController _tabController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool _isLoading = true;
  String? _error;

  List<HomeworkSet> _allHomeworks = <HomeworkSet>[];
  Map<String, HomeworkScore> _myScores = <String, HomeworkScore>{};
  Map<String, int> _myRanks = <String, int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final homeworks = await _repository.getPublishedHomeworkSets();
      final scoreMap = await _repository.getCurrentUserHomeworkScoreMap(
        homeworkIds: homeworks.map((h) => h.id).toList(),
      );
      final attemptedHomeworkIds = scoreMap.keys.toList();
      final rankEntries = await Future.wait(
        attemptedHomeworkIds.map((homeworkId) async {
          final rank = await _repository.getCurrentUserRank(homeworkId: homeworkId);
          return MapEntry<String, int?>(homeworkId, rank);
        }),
      );
      final rankMap = <String, int>{};
      for (final entry in rankEntries) {
        if (entry.value != null) {
          rankMap[entry.key] = entry.value!;
        }
      }

      if (!mounted) return;
      setState(() {
        _allHomeworks = homeworks;
        _myScores = scoreMap;
        _myRanks = rankMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  _HomeworkTab _tabFor(HomeworkSet homework) {
    if (_myScores.containsKey(homework.id)) {
      return _HomeworkTab.completed;
    }

    final nowUtc = _now.toUtc();
    final startsAt = homework.startsAt?.toUtc();
    final endsAt = homework.endsAt?.toUtc();

    if (startsAt != null && nowUtc.isBefore(startsAt)) {
      return _HomeworkTab.upcoming;
    }
    if (endsAt != null && nowUtc.isAfter(endsAt)) {
      return _HomeworkTab.completed;
    }
    return _HomeworkTab.active;
  }

  List<HomeworkSet> _itemsFor(_HomeworkTab tab) {
    final items = _allHomeworks.where((h) => _tabFor(h) == tab).toList();

    switch (tab) {
      case _HomeworkTab.active:
        items.sort((a, b) {
          final ae = a.endsAt ?? a.createdAt;
          final be = b.endsAt ?? b.createdAt;
          return ae.compareTo(be);
        });
        break;
      case _HomeworkTab.upcoming:
        items.sort((a, b) {
          final as = a.startsAt ?? a.createdAt;
          final bs = b.startsAt ?? b.createdAt;
          return as.compareTo(bs);
        });
        break;
      case _HomeworkTab.completed:
        items.sort((a, b) {
          final ad = _myScores[a.id]?.submittedAt ?? a.endsAt ?? a.createdAt;
          final bd = _myScores[b.id]?.submittedAt ?? b.endsAt ?? b.createdAt;
          return bd.compareTo(ad);
        });
        break;
    }

    return items;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final totalSeconds = duration.inSeconds;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _openDetails(HomeworkSet homework) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkDetailsScreen(
          initialHomework: homework,
          initialScore: _myScores[homework.id],
        ),
      ),
    );
    if (changed == true && mounted) {
      _loadData();
    }
  }

  Future<void> _openLeaderboard(HomeworkSet homework) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkLeaderboardScreen(homework: homework),
      ),
    );
  }

  Future<void> _openResult(HomeworkSet homework) async {
    final score = _myScores[homework.id];
    if (score == null) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkResultScreen(
          homework: homework,
          score: score,
        ),
      ),
    );
  }

  Future<void> _startHomework(HomeworkSet homework, {required bool retry}) async {
    final l10n = AppLocalizations.of(context)!;
    final alreadySubmitted = _myScores.containsKey(homework.id);
    if (alreadySubmitted && !retry) {
      return;
    }
    if (alreadySubmitted && !homework.retryAllowed) {
      return;
    }

    if (!homework.retryAllowed && !alreadySubmitted) {
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

    try {
      final questions = await _repository.getPreparedHomeworkQuestions(homework);
      if (questions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quizNoQuestions)),
        );
        return;
      }

      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            isExamMode: true,
            quizMode: QuizMode.simulation,
            isHomeworkMode: true,
            homeworkSet: homework,
            homeworkQuestions: questions,
            homeworkTimeLimitMinutes: homework.timeLimitMinutes,
          ),
        ),
      );
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.homeworkFailedToStart}: $e')),
      );
    }
  }

  Widget _buildHomeworkCard(HomeworkSet homework, _HomeworkTab tab) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final myScore = _myScores[homework.id];
    final myRank = _myRanks[homework.id];
    final questionCount = homework.questionCount ?? 0;
    final canRetry = tab == _HomeworkTab.completed &&
        myScore != null &&
        homework.retryAllowed;

    final Color badgeColor;
    final String badgeText;
    switch (tab) {
      case _HomeworkTab.active:
        badgeColor = theme.colorScheme.primaryContainer;
        badgeText = l10n.homeworkActiveNow.toUpperCase();
        break;
      case _HomeworkTab.upcoming:
        badgeColor = theme.colorScheme.tertiaryContainer;
        badgeText = l10n.homeworkUpcoming.toUpperCase();
        break;
      case _HomeworkTab.completed:
        badgeColor = theme.colorScheme.secondaryContainer;
        badgeText = l10n.homeworkCompleted.toUpperCase();
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${l10n.homeworkQuestionCount}: $questionCount'),
                Text('${l10n.homeworkTimeLimit}: ${homework.timeLimitMinutes} min'),
                if (tab == _HomeworkTab.active && homework.endsAt != null)
                  Text(
                    '${l10n.homeworkTimeRemaining}: ${_formatDuration(homework.endsAt!.difference(_now))}',
                  ),
                if (tab == _HomeworkTab.upcoming && homework.startsAt != null)
                  Text(
                    '${l10n.homeworkStartsIn}: ${_formatDuration(homework.startsAt!.difference(_now))}',
                  ),
                if (tab == _HomeworkTab.completed && myScore != null)
                  Text('${l10n.resultScore}: ${myScore.scorePercentage}%'),
                if (tab == _HomeworkTab.completed && myScore != null)
                  Text(
                    '${l10n.resultCorrect}: ${myScore.correctAnswers} • ${l10n.resultErrors}: ${myScore.wrongAnswers}',
                  ),
                if (tab == _HomeworkTab.completed && myScore != null)
                  Text(
                    '${l10n.homeworkSubmitted}: ${_formatDateTime(myScore.submittedAt)}',
                  ),
                if (tab == _HomeworkTab.completed && myRank != null)
                  Text('${l10n.homeworkRank}: #$myRank'),
              ],
            ),
            const SizedBox(height: 12),
            if (tab == _HomeworkTab.completed && myScore != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openDetails(homework),
                      child: Text(l10n.homeworkViewDetails),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openResult(homework),
                      child: Text(l10n.homeworkViewResult),
                    ),
                  ),
                  if (canRetry) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _startHomework(homework, retry: true),
                        child: Text(l10n.homeworkRetry),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => _openLeaderboard(homework),
                  child: Text(l10n.homeworkLeaderboard),
                ),
              ),
            ] else if (tab == _HomeworkTab.active && myScore == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openDetails(homework),
                      child: Text(l10n.homeworkViewDetails),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _startHomework(homework, retry: false),
                      child: Text(l10n.homeworkStartLabel),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openDetails(homework),
                  child: Text(l10n.homeworkViewDetails),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(_HomeworkTab tab) {
    final l10n = AppLocalizations.of(context)!;
    final items = _itemsFor(tab);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(child: Text(l10n.homeworkNoItems));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildHomeworkCard(items[index], tab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeworkTitle),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.78),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.homeworkActiveNow),
            Tab(text: l10n.homeworkUpcoming),
            Tab(text: l10n.homeworkCompleted),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_HomeworkTab.active),
          _buildTabContent(_HomeworkTab.upcoming),
          _buildTabContent(_HomeworkTab.completed),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _loadData();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
