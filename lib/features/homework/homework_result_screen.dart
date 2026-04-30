import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/homework_score.dart';
import '../../models/homework_set.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../quiz/result_review_screen.dart';
import 'homework_leaderboard_screen.dart';
import 'homework_localizations.dart';

class HomeworkResultScreen extends StatelessWidget {
  const HomeworkResultScreen({
    super.key,
    required this.homework,
    required this.score,
    this.questions,
    this.userAnswers,
  });

  final HomeworkSet homework;
  final HomeworkScore score;
  final List<Question>? questions;
  final Map<int, bool>? userAnswers;

  String _formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasReviewData = questions != null &&
        userAnswers != null &&
        questions!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homework.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('${l10n.resultScore}: ${score.scorePercentage}%'),
                  const SizedBox(height: 8),
                  Text('${l10n.resultCorrect}: ${score.correctAnswers}'),
                  const SizedBox(height: 8),
                  Text('${l10n.resultErrors}: ${score.wrongAnswers}'),
                  const SizedBox(height: 8),
                  Text('${l10n.quizUnanswered}: ${score.skippedAnswers}'),
                  const SizedBox(height: 8),
                  Text('${l10n.resultTime}: ${_formatSeconds(score.durationSeconds)}'),
                  const SizedBox(height: 8),
                  Text('${l10n.homeworkSubmitted}: ${score.submittedAt.toLocal()}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.homeworkBackToList),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeworkLeaderboardScreen(homework: homework),
                ),
              );
            },
            child: Text(l10n.homeworkLeaderboard),
          ),
          if (hasReviewData) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultReviewScreen(
                      questions: questions!,
                      userAnswers: userAnswers!,
                      correctCount: score.correctAnswers,
                      errorsCount: score.wrongAnswers,
                      isPassed: score.wrongAnswers <= 4,
                      durationSeconds: score.durationSeconds ?? 0,
                      quizMode: QuizMode.simulation,
                      showOnlyErrors: false,
                    ),
                  ),
                );
              },
              child: Text(l10n.homeworkReviewAnswers),
            ),
          ],
        ],
      ),
    );
  }
}
