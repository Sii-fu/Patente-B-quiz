import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:photo_view/photo_view.dart';
import '../../utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../models/homework_score.dart';
import '../../models/homework_set.dart';
import '../../repositories/homework_repository.dart';
import '../../services/quiz_repository.dart';
import '../../services/quiz_service.dart';
import '../../services/repository_provider.dart';
import '../../services/tts_helper.dart';
import '../../services/profile_stats_service.dart';
import '../../utils/constants.dart';
import '../../widgets/quiz_image.dart';
import '../homework/homework_result_screen.dart';
import 'result_minimalist_screen.dart';

class QuizScreen extends StatefulWidget {
  final bool isExamMode;
  final QuizMode quizMode;
  final int? topicId;
  final bool isHomeworkMode;
  final HomeworkSet? homeworkSet;
  final List<Question>? homeworkQuestions;
  final int? homeworkTimeLimitMinutes;

  const QuizScreen({
    super.key,
    this.isExamMode = true,
    this.quizMode = QuizMode.simulation,
    this.topicId,
    this.isHomeworkMode = false,
    this.homeworkSet,
    this.homeworkQuestions,
    this.homeworkTimeLimitMinutes,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  final ScrollController _questionNumbersScrollController = ScrollController();
  final TtsHelper _ttsHelper = TtsHelper();
  final AudioPlayer _audioPlayer = AudioPlayer(); // for custom voice
  late QuizRepository _quizRepository;
  final QuizService _quizService = QuizService();
  final HomeworkRepository _homeworkRepository = HomeworkRepository();
  
  List<Question> _questions = [];
  final Map<int, bool> _userAnswers = {};
  bool _isLoading = true;
  String? _error;
  
  // Timer
  late Timer _timer;
  int _secondsRemaining = 20 * 60; // 20 minutes
  int _quizDurationSeconds = 20 * 60;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  bool _inputLocked = false;
  
  // Language state - cycles through Italian → Bangla → English
  String _currentQuestionLanguage = 'it'; // Always start with Italian
  int _currentPage = 0;

  // Custom audio playback state
  bool _isCustomAudioPlaying = false;
  bool _isCustomAudioBuffering = false;

  // TTS audio player (for pre-recorded audio URLs)
  AudioPlayer? _ttsAudioPlayer;
  bool _isTtsPlaying = false;
  String? _currentTtsAudioUrl;
  Completer<void>? _ttsOperationLock;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _initializeQuizDuration();
    _loadQuestions();
    _startTimer();
    _ttsHelper.init(); // Initialize TTS
  }

  void _initializeQuizDuration() {
    final minutes = widget.homeworkTimeLimitMinutes ?? 20;
    _quizDurationSeconds = minutes * 60;
    _secondsRemaining = _quizDurationSeconds;
  }

  void _initializeRepository() {
    _quizRepository = RepositoryProvider.quizRepository;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _questionNumbersScrollController.dispose();
    _ttsHelper.stop();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(_pauseAndRewind(_audioPlayer));
      unawaited(_pauseAndRewindOptional(_ttsAudioPlayer));
    } else {
      unawaited(_audioPlayer.dispose());
      final ttsAudioPlayer = _ttsAudioPlayer;
      if (ttsAudioPlayer != null) {
        unawaited(ttsAudioPlayer.dispose());
      }
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hasSubmitted) {
        _timer.cancel();
        return;
      }

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      List<Question> questions;
      if (widget.isHomeworkMode) {
        if (widget.homeworkQuestions != null && widget.homeworkQuestions!.isNotEmpty) {
          questions = List<Question>.from(widget.homeworkQuestions!);
        } else if (widget.homeworkSet != null) {
          questions =
              await _homeworkRepository.getPreparedHomeworkQuestions(widget.homeworkSet!);
        } else {
          throw Exception('Homework configuration is missing.');
        }
      } else if (widget.topicId != null) {
        questions = await _quizRepository.getQuestionsForTopic(widget.topicId!);
      } else if (widget.quizMode == QuizMode.simulation) {
        questions = await _quizService.fetchRandomQuestions();
      } else if (widget.quizMode == QuizMode.reviewErrors) {
        // For review errors, we still need QuizService for now
        // TODO: Add error tracking to QuizRepository
        questions = [];
      } else {
        questions = await _quizRepository.getRandomQuestions();
      }

      if (questions.isEmpty) {
        setState(() {
          _error = 'No questions available';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      // Scroll to center first question after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentQuestion(0);
          _preloadCurrentQuestionAudio();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(int questionIndex, bool selectedTrue) {
    if (_inputLocked || _isSubmitting || _hasSubmitted) {
      return;
    }

    HapticFeedback.mediumImpact();
    
    setState(() {
      _userAnswers[questionIndex] = selectedTrue;
    });

    // Training mode: show instant feedback
    if (!widget.isExamMode) {
      final isCorrect = _questions[questionIndex].isTrue == selectedTrue;
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(isCorrect ? '✓ Correct!' : '✗ Incorrect'),
            ],
          ),
          backgroundColor: isCorrect ? AppTheme.successGreen : Theme.of(context).colorScheme.error,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Auto-advance after a brief delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (questionIndex < _questions.length - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _autoSubmitQuiz() {
    if (_isSubmitting || _hasSubmitted) return;
    final l10n = AppLocalizations.of(context)!;
    
    _ttsHelper.stop();
    setState(() => _inputLocked = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quizTimeUp),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _submitQuiz();
      }
    });
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting || _hasSubmitted) return;
    if (_questions.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _inputLocked = true;
    });

    try {
      final durationSeconds = _quizDurationSeconds - _secondsRemaining;

      // Calculate results
      int errorsCount = 0;
      for (int i = 0; i < _questions.length; i++) {
        final userAnswer = _userAnswers[i];
        if (userAnswer == null || userAnswer != _questions[i].isTrue) {
          errorsCount++;
        }
      }

      final correctCount = _questions.length - errorsCount;
      final isPassed = errorsCount <= 4;

      // Create QuizSession for submission
      final quizSession = QuizSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: Supabase.instance.client.auth.currentUser?.id ?? 'guest',
        mode: widget.quizMode,
        totalQuestions: _questions.length,
        errorsCount: errorsCount,
        isPassed: isPassed,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
      );

      // Create list of QuizAnswer objects from questions and user answers
      final quizAnswers = _questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        final userAnswer = _userAnswers[index];
        
        return QuizAnswer(
          id: DateTime.now().millisecondsSinceEpoch + index,
          userId: quizSession.userId,
          sessionId: quizSession.id,
          questionId: question.id,
          selectedTrue: userAnswer ?? false,
          isCorrect: userAnswer == question.isTrue,
          createdAt: DateTime.now(),
        );
      }).toList();

      HomeworkScore? homeworkScore;
      SubmissionResult? submissionResult;
      if (widget.isHomeworkMode && widget.homeworkSet != null) {
        final attemptResult = await _homeworkRepository.submitHomeworkAttempt(
          homework: widget.homeworkSet!,
          questions: _questions,
          userAnswers: _userAnswers,
          durationSeconds: durationSeconds,
        );
        homeworkScore = HomeworkScore(
          id: '${attemptResult.homeworkId}-${attemptResult.sessionId}',
          homeworkSetId: attemptResult.homeworkId,
          userId: quizSession.userId,
          sessionId: attemptResult.sessionId,
          correctAnswers: attemptResult.correctCount,
          wrongAnswers: attemptResult.wrongCount,
          skippedAnswers: attemptResult.unansweredCount,
          totalQuestions: attemptResult.totalQuestions,
          score: attemptResult.score,
          scorePercentage: attemptResult.score.round(),
          durationSeconds: attemptResult.durationSeconds,
          submittedAt: attemptResult.submittedAt,
        );
      } else {
        // Submit using QuizRepository (handles online/offline)
        submissionResult =
            await _quizRepository.submitQuizResult(quizSession, quizAnswers);
      }

      // Record stats for dashboard (streak, progress, errors) - sync with Supabase
      try {
        final statsService = ProfileStatsService();
        await statsService.recordQuizResult(
          correctAnswers: correctCount,
          totalQuestions: _questions.length,
        );
      } catch (e) {
        debugPrint('Error recording dashboard stats: $e');
      }

      _hasSubmitted = true;
      _timer.cancel();

      // Show appropriate feedback based on submission status
      if (mounted) {
        if (!widget.isHomeworkMode && (submissionResult?.isOnline ?? false)) {
          // Successfully uploaded to cloud
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quiz result saved successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Navigate to result screen
        if (widget.isHomeworkMode && widget.homeworkSet != null && homeworkScore != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeworkResultScreen(
                homework: widget.homeworkSet!,
                score: homeworkScore!,
                questions: _questions,
                userAnswers: _userAnswers,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultMinimalistScreen(
                questions: _questions,
                userAnswers: _userAnswers,
                correctCount: correctCount,
                errorsCount: errorsCount,
                isPassed: isPassed,
                durationSeconds: durationSeconds,
                quizMode: widget.quizMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _inputLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showSubmitConfirmation() async {
    if (_isSubmitting || _hasSubmitted || _inputLocked) return;
    final answeredCount = _userAnswers.length;
    final totalCount = _questions.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Theme.of(context).colorScheme.onSecondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submit Quiz?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip(
                            icon: Icons.check_circle,
                            label: 'Answered',
                            value: '$answeredCount',
                            color: AppTheme.successGreen,
                          ),
                          _buildStatChip(
                            icon: Icons.help_outline,
                            label: 'Remaining',
                            value: '${totalCount - answeredCount}',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                      
                      if (answeredCount < totalCount) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Unanswered questions will be marked as incorrect',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.secondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Are you sure you want to submit your quiz?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _submitQuiz();
    }
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackConfirmation() async {
    if (_isSubmitting || _hasSubmitted || _inputLocked) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            const Text('Exit Quiz?'),
          ],
        ),
        content: const Text(
          'Your progress will be lost if you exit now. Are you sure you want to go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  /// Helper method to transform image URL - same logic as QuizImage widget
  String _getFullImageUrl(String imageUrl) {
    // If already a full URL, use it directly
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Construct Supabase Storage URL
    final supabaseUrl = AppConstants.supabaseUrl;
    const storageBucket = 'question-images';
    
    return '$supabaseUrl/storage/v1/object/public/$storageBucket/$imageUrl';
  }

  void _showImageDialog(String imageUrl, String title) {
    // Transform URL using same logic as QuizImage
    final fullUrl = _getFullImageUrl(imageUrl);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(fullUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Image not available',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleLanguage() {
    HapticFeedback.selectionClick();
    setState(() {
      // Cycle: Italian → Bangla → English → Italian
      if (_currentQuestionLanguage == 'it') {
        _currentQuestionLanguage = 'bn';
      } else if (_currentQuestionLanguage == 'bn') {
        _currentQuestionLanguage = 'en';
      } else {
        _currentQuestionLanguage = 'it';
      }
    });
    _preloadCurrentQuestionAudio();
  }

  Future<void> _ensureTtsAudioPlayerInitialized() async {
    if (_ttsAudioPlayer != null) return;

    _ttsAudioPlayer = AudioPlayer();

    _ttsAudioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isTtsPlaying = state.playing);
      }
    });

    _ttsAudioPlayer!.processingStateStream.listen((state) {
      if (mounted && state == ProcessingState.completed) {
        setState(() => _isTtsPlaying = false);
      }
    });
  }

  Future<void> _runTtsOperation(Future<void> Function() operation) async {
    while (_ttsOperationLock != null) {
      await _ttsOperationLock!.future;
    }
    final completer = Completer<void>();
    _ttsOperationLock = completer;
    try {
      await operation();
    } finally {
      _ttsOperationLock = null;
      completer.complete();
    }
  }

  Future<void> _pauseAndRewind(AudioPlayer player) async {
    await player.pause();
    await player.seek(Duration.zero);
  }

  Future<void> _pauseAndRewindOptional(AudioPlayer? player) async {
    if (player == null) return;
    await player.pause();
    await player.seek(Duration.zero);
  }

  Future<void> _preloadCurrentQuestionAudio({String? languageCode}) async {
    if (_questions.isEmpty || _currentPage >= _questions.length) return;

    final question = _questions[_currentPage];
    final lang = languageCode ?? _currentQuestionLanguage;
    final audioUrl = question.getAudioUrl(lang);
    if (audioUrl == null || audioUrl.isEmpty) return;

    await _ensureTtsAudioPlayerInitialized();
    await _runTtsOperation(() async {
      if (_currentTtsAudioUrl == audioUrl && _ttsAudioPlayer!.audioSource != null) return;
      try {
        await _ttsAudioPlayer!.setUrl(audioUrl);
        _currentTtsAudioUrl = audioUrl;
      } catch (e) {
        debugPrint('⚠️ Quiz audio preload skipped: $e');
      }
    });
  }

  Future<void> _speakQuestion() async {
    HapticFeedback.mediumImpact();
    
    // Stop custom audio if playing
    if (_isCustomAudioPlaying) {
      await _pauseAndRewind(_audioPlayer);
      if (mounted) setState(() { _isCustomAudioPlaying = false; });
    }
    
    if (_currentPage >= _questions.length) return;
    
    // Toggle off if already playing
    if (_isTtsPlaying) {
      await _pauseAndRewindOptional(_ttsAudioPlayer);
      setState(() => _isTtsPlaying = false);
      return;
    }
    
    final question = _questions[_currentPage];
    final audioUrl = question.getAudioUrl(_currentQuestionLanguage);
    
    // Try to play from URL first, fall back to TTS if no URL available
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _playTtsFromUrl(audioUrl);
    } else {
      // Fallback to device TTS
      final text = question.getText(_currentQuestionLanguage);
      final success = await _ttsHelper.speak(text, _currentQuestionLanguage);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.volume_up : Icons.volume_off,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Playing audio...' : 'Audio not available'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: success ? null : Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playTtsFromUrl(String audioUrl) async {
    await _ensureTtsAudioPlayerInitialized();
    
    try {
      setState(() => _isTtsPlaying = true);
      await _runTtsOperation(() async {
        if (_currentTtsAudioUrl != audioUrl || _ttsAudioPlayer!.audioSource == null) {
          await _ttsAudioPlayer!.setUrl(audioUrl);
          _currentTtsAudioUrl = audioUrl;
        }
        await _ttsAudioPlayer!.play();
      });
    } catch (e) {
      debugPrint('❌ TTS audio playback error: $e');
      setState(() => _isTtsPlaying = false);
      
      // Fallback to device TTS on error
      final question = _questions[_currentPage];
      final text = question.getText(_currentQuestionLanguage);
      await _ttsHelper.speak(text, _currentQuestionLanguage);
    }
  }

  Future<void> _playCustomAudio(String audioUrl) async {
    HapticFeedback.mediumImpact();

    // Check connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity == ConnectivityResult.none;
    if (isOffline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Internet connection required to hear the instructor\'s explanation.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Stop TTS
    _ttsHelper.stop();

    if (_isCustomAudioPlaying) {
      await _pauseAndRewind(_audioPlayer);
      if (mounted) setState(() { _isCustomAudioPlaying = false; });
      return;
    }

    setState(() {
      _isCustomAudioBuffering = true;
      _isCustomAudioPlaying = false;
    });

    try {
      await _audioPlayer.setUrl(audioUrl);
      _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isCustomAudioPlaying = state.playing;
          _isCustomAudioBuffering =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
        }
      });
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCustomAudioBuffering = false;
          _isCustomAudioPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play audio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'it':
        return 'Italiano';
      case 'en':
        return 'English';
      case 'bn':
        return 'বাংলা';
      default:
        return 'Italiano';
    }
  }

  // Build bottom answer button (for new UI)
  Widget _buildBottomAnswerButton({
    required BuildContext context,
    required String label,
    required bool isTrueAnswer,
    required bool isSelected,
    required VoidCallback onTap,

  }) {
    final theme = Theme.of(context);
    final activeColor = isTrueAnswer ? AppTheme.successGreen : AppTheme.errorRed;
    final disabled = _inputLocked || _isSubmitting || _hasSubmitted;
    return InkWell(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap();
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : theme.colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToCurrentQuestion(int index) {
    if (!_questionNumbersScrollController.hasClients) return;
    
    // Calculate the position to center the current question
    // Each circle is 34px wide + 8px margin = 42px total
    final itemWidth = 42.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (itemWidth / 2);
    final targetScroll = (index * itemWidth) - centerOffset;
    
    _questionNumbersScrollController.animateTo(
      targetScroll.clamp(0.0, _questionNumbersScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.quizLoading,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 24),
                Text(
                  _error ?? l10n.quizNoQuestions,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // ============= TOP BAR WITH GRADIENT =============
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Back Button
                    InkWell(
                      onTap: (_isSubmitting || _hasSubmitted) ? null : _showBackConfirmation,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Timer (centered)
                    Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        color: _secondsRemaining < 60
                            ? AppTheme.errorRed
                            : theme.colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Submit Button (FINE)
                    InkWell(
                      onTap: (_isSubmitting || _hasSubmitted) ? null : _showSubmitConfirmation,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              l10n.quizFinish,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============= QUESTION NUMBERS ROW =============
          Container(
            height: 50,
            color: theme.colorScheme.surface,
            child: ListView.builder(
              controller: _questionNumbersScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isAnswered = _userAnswers.containsKey(index);
                final isCurrent = index == _currentPage;
                
                Color backgroundColor = theme.colorScheme.surface;
                Color borderColor = theme.colorScheme.primary;
                Color textColor = theme.colorScheme.primary;
                
                if (isAnswered) {
                  backgroundColor = theme.colorScheme.primary;
                  textColor = Colors.white;
                }
                
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? borderColor : borderColor.withOpacity(0.5),
                        width: isCurrent ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ============= MAIN CONTENT AREA =============
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _isCustomAudioPlaying = false;
                    _isCustomAudioBuffering = false;
                  });
                  _ttsHelper.stop();
                  unawaited(_pauseAndRewind(_audioPlayer));
                  // Scroll question number to center
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentQuestion(index);
                    _preloadCurrentQuestionAudio();
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final subtopic = question.subtopic;
                  final isAnswered = _userAnswers.containsKey(index);
                  final selectedAnswer = _userAnswers[index];

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              
                              // Images Section
                              if (subtopic?.imageUrl != null || question.imageUrl != null)
                                _buildImageSection(question, subtopic),
                              
                              const SizedBox(height: 24),

                              // Question Text
                              Builder(
                                builder: (context) {
                                  final questionStyle = Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      );

                                  return Text(
                                    question.getText(_currentQuestionLanguage),
                                    style: questionStyle,
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Audio Buttons Row: TTS + Custom Voice
                              _buildAudioButtonsRow(question),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // ============= BOTTOM ANSWER BUTTONS =============
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Builder(
                            builder: (context) {
                              final trueButton = Expanded(
                                child: _buildBottomAnswerButton(
                                  context: context,
                                  label: l10n.quizAnswerTrue,
                                  isTrueAnswer: true,
                                  isSelected: isAnswered && selectedAnswer == true,
                                  onTap: () => _answerQuestion(index, true),
                                ),
                              );
                              final falseButton = Expanded(
                                child: _buildBottomAnswerButton(
                                  context: context,
                                  label: l10n.quizAnswerFalse,
                                  isTrueAnswer: false,
                                  isSelected: isAnswered && selectedAnswer == false,
                                  onTap: () => _answerQuestion(index, false),
                                ),
                              );

                              return Row(
                                children: [
                                  trueButton,
                                  const SizedBox(width: 12),
                                  falseButton,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the two side-by-side audio buttons (TTS + Custom Voice).
  Widget _buildAudioButtonsRow(Question question) {
    final hasCustomAudio = question.explanationAudioUrl != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Button 1: Standard TTS ──────────────────────────────────────
        Tooltip(
          message: 'Read Aloud (TTS)',
          child: InkWell(
            onTap: _speakQuestion,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.volume_up,
                size: 28,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // ── Button 2: Custom Voice (only if audio exists) ───────────────
        if (hasCustomAudio) ...[
          const SizedBox(width: 16),
          Tooltip(
            message: "Instructor's Explanation",
            child: InkWell(
              onTap: () => _playCustomAudio(question.explanationAudioUrl!),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: _isCustomAudioPlaying
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: _isCustomAudioBuffering
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.successGreen,
                        ),
                      )
                    : Icon(
                        _isCustomAudioPlaying
                            ? Icons.pause_circle_filled
                            : Icons.record_voice_over,
                        size: 28,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Build image section with max 2 images per row
  Widget _buildImageSection(Question question, dynamic subtopic) {
    List<Widget> images = [];
    
    if (subtopic?.imageUrl != null) {
      images.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _showImageDialog(
              subtopic!.imageUrl!,
              subtopic.getName(_currentQuestionLanguage),
            ),
            child: _buildImageCard(subtopic!.imageUrl!),
          ),
        ),
      );
    }
    
    if (question.imageUrl != null) {
      images.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _showImageDialog(
              question.imageUrl!,
              'Question Image',
            ),
            child: _buildImageCard(question.imageUrl!),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QuizImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  // 2 separate language buttons showing the other 2 languages
  Widget _buildLanguageButtons() {
    // Get the other 2 languages (not currently selected)
    List<String> otherLanguages = ['it', 'bn', 'en']
        .where((lang) => lang != _currentQuestionLanguage)
        .toList();

    return Row(
      children: [
        _buildLanguageButton(otherLanguages[0]),
        const SizedBox(width: 12),
        _buildLanguageButton(otherLanguages[1]),
      ],
    );
  }

  Widget _buildLanguageButton(String langCode) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentQuestionLanguage = langCode;
        });
        _preloadCurrentQuestionAudio(languageCode: langCode);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Text(
          _getLanguageShortName(langCode),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _getLanguageShortName(String code) {
    switch (code) {
      case 'it':
        return 'ITA';
      case 'en':
        return 'ENG';
      case 'bn':
        return 'Bangla';
      default:
        return 'ITA';
    }
  }

  // Large answer buttons for bottom bar
  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? color : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withOpacity(0.4) : theme.shadowColor.withOpacity(0.1),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              if (isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.onPrimary : color,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
