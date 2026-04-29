import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../utils/theme.dart';
import '../../providers/language_provider.dart';
import '../../services/tts_helper.dart';

/// Page 4: Quiz Review - Detailed Question Breakdown
/// Shows each question with correct/incorrect indication
class ResultReviewScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, bool> userAnswers;
  final int correctCount;
  final int errorsCount;
  final bool isPassed;
  final int durationSeconds;
  final QuizMode quizMode;
  final bool showOnlyErrors;

  const ResultReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.correctCount,
    required this.errorsCount,  
    required this.isPassed,
    required this.durationSeconds,
    required this.quizMode,
    this.showOnlyErrors = false,
  });

  @override
  State<ResultReviewScreen> createState() => _ResultReviewScreenState();
}

class _ResultReviewScreenState extends State<ResultReviewScreen> {
  late bool _showOnlyErrors;
  final TtsHelper _ttsHelper = TtsHelper();
  final Map<int, String> _questionLanguages = {}; // Track language per question
  bool _isSpeaking = false;
  int? _speakingQuestionIndex;
  
  // Audio player for TTS from URL
  AudioPlayer? _ttsAudioPlayer;

  @override
  void initState() {
    super.initState();
    _showOnlyErrors = widget.showOnlyErrors;
    _ttsHelper.init();
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    _ttsAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _speak(String text, String languageCode, int questionIndex, {String? audioUrl}) async {
    if (_isSpeaking && _speakingQuestionIndex == questionIndex) {
      _ttsHelper.stop();
      await _ttsAudioPlayer?.stop();
      setState(() {
        _isSpeaking = false;
        _speakingQuestionIndex = null;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
      _speakingQuestionIndex = questionIndex;
    });
    
    // Try to play from URL first, fall back to device TTS
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _playTtsFromUrl(audioUrl);
    } else {
      final success = await _ttsHelper.speak(text, languageCode);
      
      if (!success) {
        setState(() {
          _isSpeaking = false;
          _speakingQuestionIndex = null;
        });
      } else {
        // Auto-reset after speaking completes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _speakingQuestionIndex = null;
            });
          }
        });
      }
    }
  }

  Future<void> _playTtsFromUrl(String audioUrl) async {
    // Initialize TTS audio player if needed
    if (_ttsAudioPlayer == null) {
      _ttsAudioPlayer = AudioPlayer();
      
      _ttsAudioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isSpeaking = state.playing);
        }
      });
      
      _ttsAudioPlayer!.processingStateStream.listen((state) {
        if (mounted && state == ProcessingState.completed) {
          setState(() {
            _isSpeaking = false;
            _speakingQuestionIndex = null;
          });
        }
      });
    }
    
    try {
      await _ttsAudioPlayer!.setUrl(audioUrl);
      await _ttsAudioPlayer!.play();
    } catch (e) {
      debugPrint('❌ TTS audio playback error: $e');
      setState(() {
        _isSpeaking = false;
        _speakingQuestionIndex = null;
      });
    }
  }

  String _getQuestionLanguage(int questionIndex, String defaultLanguage) {
    return _questionLanguages[questionIndex] ?? 'it'; // Always start with Italian
  }

  void _setQuestionLanguage(int questionIndex, String languageCode) {
    setState(() {
      _questionLanguages[questionIndex] = languageCode;
    });
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.locale.languageCode;
    final filteredQuestions = _getFilteredQuestions();

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrandBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _ttsHelper.stop();
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.resultReview,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Toggle Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: !_showOnlyErrors
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: Icon(
                              Icons.list,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                            label: Text(
                              l10n.resultReviewShowAll,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrandBlue,
                              disabledBackgroundColor: AppTheme.primaryBrandBlue,
                              disabledForegroundColor: theme.colorScheme.onPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _showOnlyErrors = false;
                              });
                            },
                            icon: Icon(
                              Icons.list,
                              size: 20,
                              color: AppTheme.primaryBrandBlue,
                            ),
                            label: Text(
                              l10n.resultReviewShowAll,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBrandBlue,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBrandBlue,
                              side: BorderSide(
                                color: AppTheme.primaryBrandBlue,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: _showOnlyErrors
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: Icon(
                              Icons.error_outline,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                            label: Text(
                              l10n.resultReviewShowErrors,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                              disabledBackgroundColor: AppTheme.errorRed,
                              disabledForegroundColor: theme.colorScheme.onPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _showOnlyErrors = true;
                              });
                            },
                            icon: Icon(
                              Icons.error_outline,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
                            label: Text(
                              l10n.resultReviewShowErrors,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorRed,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: BorderSide(
                                color: AppTheme.errorRed,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 100),
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final entry = filteredQuestions[index];
                final questionIndex = entry.key;
                final question = entry.value;
                final userAnswer = widget.userAnswers[questionIndex];
                final isCorrect = userAnswer != null && userAnswer == question.isTrue;

                return _buildQuestionCard(
                  questionIndex,
                  question,
                  userAnswer,
                  isCorrect,
                  currentLanguage,
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _ttsHelper.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home),
                    label: Text(l10n.resultHome),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrandBlue,
                      side: BorderSide(
                        color: AppTheme.primaryBrandBlue,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _ttsHelper.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.resultNewQuiz),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrandBlue,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    int questionIndex,
    Question question,
    bool? userAnswer,
    bool isCorrect,
    String defaultLanguage,
  ) {
    final questionLanguage = _getQuestionLanguage(questionIndex, defaultLanguage);
    final questionText = question.getText(questionLanguage);
    final audioUrl = question.getAudioUrl(questionLanguage);
    final isSpeakingThis = _isSpeaking && _speakingQuestionIndex == questionIndex;

    // Get available languages for this question
    final List<String> availableLanguages = ['it'];
    if (question.textEn != null && question.textEn!.isNotEmpty) {
      availableLanguages.add('en');
    }
    if (question.textBn != null && question.textBn!.isNotEmpty) {
      availableLanguages.add('bn');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: availableLanguages.length > 1
            ? Border.all(
                color:  isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                width: 4,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? AppTheme.successGreen : AppTheme.errorRed)
                .withOpacity(1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Question Number and Status
          Padding(
            padding: const EdgeInsets.only(left: 20, right:20, top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.quizQuestion} ${questionIndex + 1}/${widget.questions.length}',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w400, 
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                  size: 28,
                ),
              ],
            ),
          ),

          
          // Question Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              questionText,
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Images Section (only if images exist)
          if (question.imageUrl != null || question.subtopic?.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildImageSection(question),
            ),

          if (question.imageUrl != null || question.subtopic?.imageUrl != null)
            const SizedBox(height: 16),

          // Bottom Section: Language Buttons, Correct Answer, TTS Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // First Row: Language Buttons (Left) and TTS Button (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT SIDE → Language buttons
                    Row(
                      children: [
                        _buildLanguageButton('it', questionIndex, questionLanguage),
                        const SizedBox(width: 8),
                        if (question.textBn != null && question.textBn!.isNotEmpty)
                          _buildLanguageButton('bn', questionIndex, questionLanguage),
                        if (question.textBn != null && question.textBn!.isNotEmpty)
                          const SizedBox(width: 8),
                        if (question.textEn != null && question.textEn!.isNotEmpty)
                          _buildLanguageButton('en', questionIndex, questionLanguage),
                      ],
                    ),

                    // RIGHT SIDE → TTS button
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isSpeakingThis
                            ? AppTheme.primaryBrandGreen
                            : AppTheme.primaryBrandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBrandGreen,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isSpeakingThis ? Icons.stop : Icons.volume_up,
                          color: AppTheme.primaryBrandGreen,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _speak(questionText, questionLanguage, questionIndex, audioUrl: audioUrl);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Second Row: Correct Answer Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: question.isTrue ? AppTheme.successGreen : AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.quizCorrectAnswer}: ',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        question.isTrue ? 'VERO' : 'FALSO',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        question.isTrue ? Icons.check_circle : Icons.cancel,
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String languageCode, int questionIndex, String currentLanguage) {
    final theme = Theme.of(context);
    String label;
    switch (languageCode) {
      case 'en':
        label = 'EN';
        break;
      case 'bn':
        label = 'বাং';
        break;
      default:
        label = 'IT';
    }

    final isSelected = currentLanguage == languageCode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _setQuestionLanguage(questionIndex, languageCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBrandBlue
              : AppTheme.primaryBrandBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBrandBlue,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : AppTheme.primaryBrandBlue,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(Question question) {
    final theme = Theme.of(context);
    List<Widget> images = [];

    if (question.subtopic?.imageUrl != null) {
      images.add(
        Expanded(
          child: _buildImageCard(question.subtopic!.imageUrl!),
        ),
      );
    }

    if (question.imageUrl != null) {
      images.add(
        Expanded(
          child: _buildImageCard(question.imageUrl!),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < images.length; i++) ...[
            images[i],
            if (i < images.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
          ),
        ),
      ),
    );
  }

}
