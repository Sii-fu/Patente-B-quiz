import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../repositories/vocabulary_repository.dart';
import '../../utils/theme.dart';

class WordQuestionsScreen extends StatefulWidget {
  final String targetWord;

  const WordQuestionsScreen({super.key, required this.targetWord});

  @override
  State<WordQuestionsScreen> createState() => _WordQuestionsScreenState();
}

class _WordQuestionsScreenState extends State<WordQuestionsScreen> {
  final VocabularyRepository _repo = VocabularyRepository();

  late Future<List<Question>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _repo.getQuestionsContainingWord(widget.targetWord);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.wordQuestionsTitle,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '"${widget.targetWord}"',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: FutureBuilder<List<Question>>(
                    future: _questionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: theme.colorScheme.primary),
                              const SizedBox(height: 16),
                              Text(l10n.wordQuestionsLoading),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 64,
                                    color: theme.colorScheme.error),
                                const SizedBox(height: 16),
                                Text(snapshot.error.toString(),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }

                      final questions = snapshot.data ?? [];

                      if (questions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                l10n.wordQuestionsEmpty,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Result count banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${questions.length} ${l10n.wordQuestionsFound}',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: questions.length,
                              itemBuilder: (context, index) =>
                                  _buildQuestionCard(
                                      questions[index], index, theme),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightedText(
                    question.textIt,
                    widget.targetWord,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Answer badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: question.isTrue
                    ? AppTheme.successGreen.withValues(alpha: 0.1)
                    : AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      question.isTrue ? AppTheme.successGreen : AppTheme.errorRed,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    question.isTrue ? Icons.check_circle : Icons.cancel,
                    color: question.isTrue
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    question.isTrue ? 'Vero ✓' : 'Falso ✗',
                    style: TextStyle(
                      color: question.isTrue
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  /// Builds a [RichText] that highlights every occurrence of [targetWord]
  /// inside [fullText] with bold + primary colour.
  Widget _buildHighlightedText(
      String fullText, String targetWord, ThemeData theme) {
    final lower = fullText.toLowerCase();
    final keyword = targetWord.toLowerCase();

    if (keyword.isEmpty || !lower.contains(keyword)) {
      return Text(
        fullText,
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
      );
    }

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(keyword, start);
      if (idx == -1) {
        spans.add(TextSpan(text: fullText.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: fullText.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: fullText.substring(idx, idx + keyword.length),
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ));
      start = idx + keyword.length;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
