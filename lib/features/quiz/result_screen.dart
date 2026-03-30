import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../utils/theme.dart';

class ResultScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, bool> userAnswers;
  final int correctCount;
  final int errorsCount;
  final bool isPassed;
  final int durationSeconds;
  final QuizMode quizMode;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.correctCount,
    required this.errorsCount,
    required this.isPassed,
    required this.durationSeconds,
    required this.quizMode,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  bool _showOnlyErrors = false;
  final FlutterTts _flutterTts = FlutterTts();
  final Set<int> _expandedCards = {};
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('it-IT');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text, String languageCode) async {
    HapticFeedback.mediumImpact();
    
    String ttsLanguage = 'it-IT';
    if (languageCode == 'en') {
      ttsLanguage = 'en-US';
    } else if (languageCode == 'bn') {
      ttsLanguage = 'bn-BD';
    }
    
    await _flutterTts.setLanguage(ttsLanguage);
    await _flutterTts.speak(text);
  }

  List<MapEntry<int, Question>> _getFilteredQuestions() {
    final List<MapEntry<int, Question>> questionEntries = [];
    
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final userAnswer = widget.userAnswers[i];
      final isCorrect = userAnswer != null && userAnswer == question.isTrue;
      
      if (!_showOnlyErrors || !isCorrect) {
        questionEntries.add(MapEntry(i, question));
      }
    }
    
    return questionEntries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;
    final filteredQuestions = _getFilteredQuestions();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isPassed
                      ? [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)]
                      : [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isPassed ? AppTheme.successGreen : theme.colorScheme.error)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Result Badge
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isPassed
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: widget.isPassed ? AppTheme.successGreen : theme.colorScheme.error,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isPassed
                                ? l10n.resultPromoted
                                : l10n.resultRejected,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isPassed ? AppTheme.successGreen : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.isPassed ? l10n.resultPassed : l10n.resultFailed,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        icon: Icons.check_circle_outline,
                        label: l10n.resultCorrect,
                        value: widget.correctCount.toString(),
                        color: theme.colorScheme.onPrimary,
                        theme: theme,
                      ),
                      _buildStatCard(
                        icon: Icons.cancel_outlined,
                        label: l10n.resultErrors,
                        value: widget.errorsCount.toString(),
                        color: theme.colorScheme.onPrimary,
                        theme: theme,
                      ),
                      _buildStatCard(
                        icon: Icons.timer_outlined,
                        label: l10n.resultTime,
                        value: '$minutes:${seconds.toString().padLeft(2, '0')}',
                        color: theme.colorScheme.onPrimary,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.resultShowAll),
                          icon: const Icon(Icons.list, size: 18),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.resultShowErrors),
                          icon: const Icon(Icons.error_outline, size: 18),
                        ),
                      ],
                      selected: {_showOnlyErrors},
                      onSelectionChanged: (Set<bool> newSelection) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _showOnlyErrors = newSelection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Questions Review List
            Expanded(
              child: filteredQuestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.celebration,
                            size: 72,
                            color: AppTheme.successGreen.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Perfect! No errors to review!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final entry = filteredQuestions[index];
                        final questionIndex = entry.key;
                        final question = entry.value;
                        return _buildQuestionCard(
                          questionIndex,
                          question,
                          theme,
                          l10n,
                        );
                      },
                    ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: Text(l10n.resultBackToDashboard),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.resultRetry),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    int questionIndex,
    Question question,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final userAnswer = widget.userAnswers[questionIndex];
    final isCorrect = userAnswer != null && userAnswer == question.isTrue;
    final isExpanded = _expandedCards.contains(questionIndex);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCorrect
              ? AppTheme.successGreen.withOpacity(0.3)
              : theme.colorScheme.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(questionIndex);
                } else {
                  _expandedCards.add(questionIndex);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.successGreen.withOpacity(0.1)
                              : theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: isCorrect ? AppTheme.successGreen : theme.colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.resultQuestion} ${questionIndex + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? AppTheme.successGreen : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Question Text
                  Text(
                    question.textIt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Answers Row
                  Row(
                    children: [
                      _buildAnswerChip(
                        label: '${l10n.resultYourAnswer}: ${userAnswer != null ? (userAnswer ? l10n.quizTrue : l10n.quizFalse) : 'N/A'}',
                        color: isCorrect ? AppTheme.successGreen : theme.colorScheme.error,
                        isOutlined: true,
                      ),
                      const SizedBox(width: 8),
                      _buildAnswerChip(
                        label: '${l10n.resultCorrectAnswer}: ${question.isTrue ? l10n.quizTrue : l10n.quizFalse}',
                        color: AppTheme.successGreen,
                        isOutlined: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Translation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildTtsButton(
                          icon: Icons.volume_up,
                          label: 'Italiano',
                          onPressed: () => _speak(question.textIt, 'it'),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTtsButton(
                          icon: Icons.volume_up,
                          label: 'English',
                          onPressed: () => _speak(
                            question.textEn ?? question.textIt,
                            'en',
                          ),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTtsButton(
                          icon: Icons.volume_up,
                          label: 'বাংলা',
                          onPressed: () => _speak(
                            question.textBn ?? question.textIt,
                            'bn',
                          ),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Translations
                  if (question.textEn != null) ...[
                    _buildTranslationCard(
                      language: 'English',
                      text: question.textEn!,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (question.textBn != null) ...[
                    _buildTranslationCard(
                      language: 'বাংলা',
                      text: question.textBn!,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Explanation Section
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.resultExplanation,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.explanationIt ?? l10n.resultNoExplanation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: question.explanationIt != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: question.explanationIt != null
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerChip({
    required String label,
    required Color color,
    required bool isOutlined,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTtsButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildTranslationCard({
    required String language,
    required String text,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
