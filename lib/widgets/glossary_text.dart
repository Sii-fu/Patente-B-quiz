import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/vocabulary_word.dart';
import '../repositories/vocabulary_repository.dart';
import '../screens/dashboard/word_questions_screen.dart';
import '../services/tts_helper.dart';
import '../utils/localization_helper.dart';

class GlossaryText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const GlossaryText({
    super.key,
    required this.text,
    
    this.style,
  });

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  static final RegExp _wordRegex = RegExp(r"[\p{L}']+", unicode: true);
  static Future<Map<String, VocabularyWord>>? _glossaryFuture;

  final VocabularyRepository _repo = VocabularyRepository();
  final TtsHelper _ttsHelper = TtsHelper();
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
    _glossaryFuture ??= _repo.getGlossaryMap();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  VocabularyWord? _lookupWord(
    String word,
    Map<String, VocabularyWord> glossary,
  ) {
    final normalized = word.toLowerCase();
    final direct = glossary[normalized];
    if (direct != null) {
      return direct;
    }

    if (normalized.contains("'")) {
      final afterApostrophe = normalized.split("'").last;
      if (afterApostrophe.isNotEmpty) {
        return glossary[afterApostrophe];
      }
    }

    return null;
  }

  List<InlineSpan> _buildSpans(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    Map<String, VocabularyWord> glossary,
  ) {
    final spans = <InlineSpan>[];
    var currentIndex = 0;

    for (final match in _wordRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      final word = text.substring(match.start, match.end);
      final glossaryWord = _lookupWord(word, glossary);

      if (glossaryWord != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _showGlossaryPopup(context, glossaryWord);
        _recognizers.add(recognizer);

        var highlightColor = Theme.of(context).colorScheme.primary;
        if (Theme.of(context).brightness == Brightness.dark &&
            highlightColor.computeLuminance() < 0.4) {
          highlightColor = Theme.of(context).colorScheme.primaryContainer;
        }

        spans.add(TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: highlightColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ));
      } else {
        spans.add(TextSpan(
          text: word,
          style: baseStyle,
        ));
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Future<void> _showGlossaryPopup(
    BuildContext context,
    VocabularyWord word,
  ) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.wordIt,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        _ttsHelper.speak(word.wordIt, 'it');
                      },
                    ),
                  ],
                ),
                if ((word.translationEn ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${l10n.languageEnglish}: ${word.translationEn ?? ''}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                if ((word.translationBn ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${l10n.languageBangla}: ${word.translationBn ?? ''}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WordQuestionsScreen(targetWord: word.wordIt),
                        ),
                      );
                    },
                    child: Text(l10n.vocabSeeQuestions),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    var baseStyle = defaultStyle.style.merge(widget.style);
    if (baseStyle.color == null) {
      baseStyle = baseStyle.copyWith(color: theme.colorScheme.onSurface);
    } else if (theme.brightness == Brightness.dark) {
      final luminance = baseStyle.color!.computeLuminance();
      if (luminance < 0.35) {
        baseStyle = baseStyle.copyWith(color: theme.colorScheme.onSurface);
      }
    }
    final textAlign = defaultStyle.textAlign ?? TextAlign.start;

    if (widget.text.isEmpty) {
      return Text('', style: baseStyle, textAlign: textAlign);
    }

    return FutureBuilder<Map<String, VocabularyWord>>(
      future: _glossaryFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            widget.text,
            style: baseStyle,
            textAlign: textAlign,
          );
        }

        _disposeRecognizers();
        final spans = _buildSpans(context, widget.text, baseStyle, snapshot.data!);

        return RichText(
          textAlign: textAlign,
          text: TextSpan(style: baseStyle, children: spans),
        );
      },
    );
  }
}
