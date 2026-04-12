import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../utils/theme.dart';
import '../../services/quiz_service.dart';
import '../../services/tts_helper.dart';
import '../../services/profile_stats_service.dart';
import '../../features/quiz/result_minimalist_screen.dart';

class CustomQuizScreen extends StatefulWidget {
  final int numberOfQuestions;
  final bool hasTimeLimit;
  final int timeLimit;
  final List<int> selectedTopicIds;
  final bool immediateAnswerFeedback;
  /// When provided, questions are used directly without fetching from the network.
  final List<Question>? preloadedQuestions;

  const CustomQuizScreen({
    super.key,
    required this.numberOfQuestions,
    required this.hasTimeLimit,
    required this.timeLimit,
    required this.selectedTopicIds,
    required this.immediateAnswerFeedback,
    this.preloadedQuestions,
  });

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> {
  final PageController _pageController = PageController();
  final ScrollController _questionNumbersScrollController = ScrollController();
  final QuizService _quizService = QuizService();
  final TtsHelper _ttsHelper = TtsHelper();
  
  List<Question> _questions = [];
  final Map<int, bool> _userAnswers = {};
  bool _isLoading = true;
  String? _error;
  
  // Timer
  Timer? _timer;
  int _secondsRemaining = 0;
  
  // Language state
  String _currentQuestionLanguage = 'it';
  int _currentPage = 0;
  
  // Immediate feedback state
  bool _showingFeedback = false;
  bool? _currentAnswerCorrect;
  bool _showExplanation = false;
  
  // Custom audio player state
  AudioPlayer? _audioPlayer;
  bool _isCustomAudioPlaying = false;
  bool _isCustomAudioLoading = false;
  
  // Audio player for question TTS audio (from URL)
  AudioPlayer? _ttsAudioPlayer;
  
  // TTS state
  bool _isTtsSpeaking = false;
  String? _playingLanguage; // Track which language is currently playing

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.timeLimit * 60;
    _loadQuestions();
    if (widget.hasTimeLimit) {
      _startTimer();
    }
    _ttsHelper.init(); // Initialize TTS
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _questionNumbersScrollController.dispose();
    _ttsHelper.stop();
    _audioPlayer?.dispose();
    _ttsAudioPlayer?.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      List<Question> questions;
      if (widget.preloadedQuestions != null) {
        // Use pre-loaded questions directly (e.g. from theory card)
        questions = widget.preloadedQuestions!;
      } else {
        // Use the new fetchCustomQuiz method from QuizService
        questions = await _quizService.fetchCustomQuiz(
          numberOfQuestions: widget.numberOfQuestions,
          selectedTopicIds: widget.selectedTopicIds,
        );
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      // Scroll to center first question after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentQuestion(0);
        }
      });
    } catch (e) {
      debugPrint('Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    try {
      final durationSeconds = widget.hasTimeLimit 
          ? (widget.timeLimit * 60) - _secondsRemaining
          : 0;

      // Save results to database using the new custom quiz method
      await _quizService.saveCustomQuizResults(
        questions: _questions,
        userAnswers: _userAnswers,
        durationSeconds: durationSeconds,
        selectedTopicIds: widget.selectedTopicIds.isNotEmpty 
            ? widget.selectedTopicIds 
            : null,
      );

      // Calculate results
      int errorsCount = 0;
      for (int i = 0; i < _questions.length; i++) {
        final userAnswer = _userAnswers[i];
        if (userAnswer == null || userAnswer != _questions[i].isTrue) {
          errorsCount++;
        }
      }

      final correctCount = _questions.length - errorsCount;
      
      // Calculate pass status proportionally (4 errors max for 30 questions)
      final maxAllowedErrors = (_questions.length * 4) ~/ 30;
      final isPassed = errorsCount <= maxAllowedErrors;

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

      // Navigate to result screen
      if (mounted) {
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
              quizMode: QuizMode.topic,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _answerQuestion(int questionIndex, bool selectedTrue) {
    if (_showingFeedback) return; // Prevent multiple answers during feedback
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _userAnswers[questionIndex] = selectedTrue;
    });

    final isCorrect = _questions[questionIndex].isTrue == selectedTrue;

    if (widget.immediateAnswerFeedback) {
      // Show immediate feedback card with explanation from DB
      setState(() {
        _showingFeedback = true;
        _currentAnswerCorrect = isCorrect;
        _showExplanation = true; // Auto-show explanation from DB
      });
    } else {
      // Standard mode: auto-advance
      _autoAdvanceToNext(questionIndex);
    }
  }

  void _autoAdvanceToNext(int questionIndex) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (questionIndex < _questions.length - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _continueAfterFeedback() {
    // Simply advance to next question - feedback will persist
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _autoSubmitQuiz() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quizTimeUp),
        backgroundColor: theme.colorScheme.error,
      ),
    );

    Future.delayed(const Duration(seconds: 1), _submitQuiz);
  }

  Future<void> _showSubmitConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onPrimary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.quizSubmitConfirm,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${l10n.quizSubmitMessage} $answeredCount ${l10n.quizSubmitOutOf} $totalCount ${l10n.quizSubmitQuestions}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(l10n.profileCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(l10n.quizSubmit),
                          ),
                        ),
                      ],
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

  Future<void> _showBackConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(width: 12),
            Text(l10n.quizExitTitle),
          ],
        ),
        content: Text(
          l10n.quizExitMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.quizStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.quizExit),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 64),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakQuestion() async {
    HapticFeedback.mediumImpact();
    
    if (_currentPage >= _questions.length) return;
    
    // Stop custom audio if playing
    if (_isCustomAudioPlaying) {
      await _audioPlayer?.pause();
      setState(() => _isCustomAudioPlaying = false);
    }
    
    // Toggle off if already speaking
    if (_isTtsSpeaking) {
      await _ttsAudioPlayer?.stop();
      setState(() => _isTtsSpeaking = false);
      return;
    }
    
    final question = _questions[_currentPage];
    final audioUrl = question.getAudioUrl(_currentQuestionLanguage);
    
    // Try to play from URL first, fall back to TTS if no URL available
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _playAudioFromUrl(audioUrl);
    } else {
      // Fallback to device TTS
      final text = question.getText(_currentQuestionLanguage);
      setState(() => _isTtsSpeaking = true);
      await _ttsHelper.speak(text, _currentQuestionLanguage, awaitCompletion: true);
      if (mounted) {
        setState(() => _isTtsSpeaking = false);
      }
    }
  }
  
  Future<void> _playAudioFromUrl(String audioUrl) async {
    // Initialize TTS audio player if needed
    if (_ttsAudioPlayer == null) {
      _ttsAudioPlayer = AudioPlayer();
      
      _ttsAudioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isTtsSpeaking = state.playing;
          });
        }
      });
      
      _ttsAudioPlayer!.processingStateStream.listen((state) {
        if (mounted && state == ProcessingState.completed) {
          setState(() {
            _isTtsSpeaking = false;
            _playingLanguage = null; // Reset playing language when done
          });
        }
      });
    }
    
    try {
      setState(() => _isTtsSpeaking = true);
      debugPrint('🎧 Loading audio from URL: $audioUrl');
      await _ttsAudioPlayer!.setUrl(audioUrl);
      debugPrint('▶️ Playing audio from URL');
      await _ttsAudioPlayer!.play();
    } catch (e) {
      debugPrint('❌ TTS audio playback error: $e');
      setState(() {
        _isTtsSpeaking = false;
        _playingLanguage = null;
      });
      
      // Fallback to device TTS on error
      final question = _questions[_currentPage];
      final text = question.getText(_currentQuestionLanguage);
      setState(() => _isTtsSpeaking = true);
      await _ttsHelper.speak(text, _currentQuestionLanguage, awaitCompletion: true);
      if (mounted) {
        setState(() {
          _isTtsSpeaking = false;
          _playingLanguage = null;
        });
      }
    }
  }

  Future<void> _toggleCustomAudio() async {
    HapticFeedback.mediumImpact();
    
    if (_currentPage >= _questions.length) return;
    
    final question = _questions[_currentPage];
    final audioUrl = question.explanationAudioUrl;
    
    // Check if audio is available
    if (audioUrl == null || audioUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No custom audio available for this question'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Stop TTS if speaking
    if (_isTtsSpeaking) {
      _ttsHelper.stop();
      setState(() => _isTtsSpeaking = false);
    }
    
    // Initialize audio player if needed
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isCustomAudioPlaying = state.playing;
            if (state.playing) _isCustomAudioLoading = false;
          });
        }
      });
      
      _audioPlayer!.processingStateStream.listen((state) {
        if (mounted) {
          setState(() {
            if (state == ProcessingState.ready) {
              _isCustomAudioLoading = false;
            } else if (state == ProcessingState.completed) {
              _isCustomAudioPlaying = false;
            }
          });
        }
      });
    }
    
    try {
      if (_isCustomAudioPlaying) {
        await _audioPlayer!.pause();
      } else {
        // Check if we need to load new audio (different question or not loaded)
        final currentSource = _audioPlayer!.audioSource;
        if (currentSource == null) {
          setState(() => _isCustomAudioLoading = true);
          await _audioPlayer!.setUrl(audioUrl);
        }
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      setState(() => _isCustomAudioLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _playLanguageAudio(String languageCode) async {
    HapticFeedback.mediumImpact();
    
    if (_currentPage >= _questions.length) return;
    
    // If already playing this exact language, stop it
    if (_isTtsSpeaking && _playingLanguage == languageCode) {
      await _ttsAudioPlayer?.stop();
      setState(() {
        _isTtsSpeaking = false;
        _playingLanguage = null;
      });
      return;
    }
    
    // Stop any currently playing audio
    if (_isTtsSpeaking) {
      await _ttsAudioPlayer?.stop();
    }
    if (_isCustomAudioPlaying) {
      await _audioPlayer?.pause();
      setState(() => _isCustomAudioPlaying = false);
    }
    
    // DO NOT change _currentQuestionLanguage - only play audio
    // Track which language is playing for UI feedback
    setState(() => _playingLanguage = languageCode);
    
    final question = _questions[_currentPage];
    final audioUrl = question.getAudioUrl(languageCode);
    
    debugPrint('🎵 Playing audio for language: $languageCode, URL: $audioUrl');
    
    // Try to play from URL first, fall back to TTS if no URL available
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _playAudioFromUrl(audioUrl);
    } else {
      debugPrint('⚠️ No audio URL found, falling back to TTS');
      // Fallback to device TTS
      final text = question.getText(languageCode);
      setState(() => _isTtsSpeaking = true);
      await _ttsHelper.speak(text, languageCode, awaitCompletion: true);
      if (mounted) {
        setState(() {
          _isTtsSpeaking = false;
          _playingLanguage = null;
        });
      }
    }
  }
  
  // Reset audio player when changing questions
  void _resetAudioPlayer() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isCustomAudioPlaying = false;
    _isCustomAudioLoading = false;
    
    // Also reset TTS audio player
    _ttsAudioPlayer?.stop();
    _isTtsSpeaking = false;
    _playingLanguage = null; // Reset playing language
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

  void _showTranslationDialog() {
    if (_currentPage >= _questions.length) return;
    
    final question = _questions[_currentPage];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.quizTranslations,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // English Translation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.language, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.quizEnglish,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Audio button for English
                              IconButton(
                                icon: Icon(
                                  _isTtsSpeaking && _playingLanguage == 'en'
                                      ? Icons.stop_circle
                                      : Icons.volume_up,
                                  size: 24,
                                ),
                                color: theme.colorScheme.primary,
                                onPressed: () => _playLanguageAudio('en'),
                                tooltip: 'Play English audio',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.getText('en'),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bangla Translation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.language, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.quizBangla,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Audio button for Bangla
                              IconButton(
                                icon: Icon(
                                  _isTtsSpeaking && _playingLanguage == 'bn'
                                      ? Icons.stop_circle
                                      : Icons.volume_up,
                                  size: 24,
                                ),
                                color: theme.colorScheme.primary,
                                onPressed: () => _playLanguageAudio('bn'),
                                tooltip: 'Play Bangla audio',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.getText('bn'),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.onPrimary),
              const SizedBox(height: 24),
              Text(
                l10n.quizLoading,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _questions.isEmpty) {
      final theme = Theme.of(context);
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
                Icon(Icons.error_outline, color: theme.colorScheme.onPrimary, size: 80),
                const SizedBox(height: 24),
                Text(
                  _error ?? l10n.quizNoQuestions,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.quizGoBack),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

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
                      onTap: _showBackConfirmation,
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
                    if (widget.hasTimeLimit)
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
                      onTap: _showSubmitConfirmation,
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
            color: Colors.white,
            child: ListView.builder(
              controller: _questionNumbersScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isAnswered = _userAnswers.containsKey(index);
                final isCurrent = index == _currentPage;
                
                Color backgroundColor = Colors.white;
                Color borderColor = theme.colorScheme.primary;
                Color textColor = theme.colorScheme.primary;
                
                if (widget.immediateAnswerFeedback && isAnswered) {
                  final isCorrect = _userAnswers[index] == _questions[index].isTrue;
                  backgroundColor = isCorrect ? AppTheme.successGreen : AppTheme.errorRed;
                  borderColor = isCorrect ? AppTheme.successGreen : AppTheme.errorRed;
                  textColor = Colors.white;
                } else if (isAnswered) {
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
              color: Colors.white,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  // Reset audio player when changing questions
                  _resetAudioPlayer();
                  // Stop TTS when changing questions
                  if (_isTtsSpeaking) {
                    _ttsHelper.stop();
                  }
                  
                  setState(() {
                    _currentPage = index;
                    _isTtsSpeaking = false;
                    // Keep feedback visible if question was already answered in immediate mode
                    if (widget.immediateAnswerFeedback && _userAnswers.containsKey(index)) {
                      _showingFeedback = true;
                      _currentAnswerCorrect = _userAnswers[index] == _questions[index].isTrue;
                      _showExplanation = true; // Auto-show explanation from DB
                    } else {
                      _showingFeedback = false;
                      _currentAnswerCorrect = null;
                      _showExplanation = false;
                    }
                  });
                  // Scroll question number to center
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentQuestion(index);
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final subtopic = question.subtopic;
                  final isAnswered = _userAnswers.containsKey(index);
                  final selectedAnswer = _userAnswers[index];

                  return Column(
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
                              Text(
                                question.getText(_currentQuestionLanguage),
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              // Audio Buttons: TTS + Custom audio
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // TTS Button
                                  GestureDetector(
                                    onTap: _speakQuestion,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isTtsSpeaking 
                                            ? theme.colorScheme.primary 
                                            : theme.colorScheme.primary.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        _isTtsSpeaking ? Icons.pause : Icons.volume_up,
                                        size: 28,
                                        color: _isTtsSpeaking 
                                            ? Colors.white 
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Custom Audio Button
                                  GestureDetector(
                                    onTap: _toggleCustomAudio,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isCustomAudioPlaying 
                                            ? AppTheme.successGreen 
                                            : (question.explanationAudioUrl != null && question.explanationAudioUrl!.isNotEmpty)
                                                ? AppTheme.successGreen.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                      ),
                                      child: _isCustomAudioLoading
                                          ? Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation(AppTheme.successGreen),
                                              ),
                                            )
                                          : Icon(
                                              _isCustomAudioPlaying ? Icons.stop : Icons.record_voice_over,
                                              size: 28,
                                              color: _isCustomAudioPlaying 
                                                  ? Colors.white 
                                                  : (question.explanationAudioUrl != null && question.explanationAudioUrl!.isNotEmpty)
                                                      ? AppTheme.successGreen
                                                      : Colors.grey,
                                            ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Immediate Feedback Card (show if answered in immediate mode)
                              if (widget.immediateAnswerFeedback && isAnswered && _currentAnswerCorrect != null)
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 120.0, left: 16, right: 16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: _currentAnswerCorrect!
                                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                                            : AppTheme.errorRed.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _currentAnswerCorrect! ? AppTheme.successGreen : AppTheme.errorRed,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                _currentAnswerCorrect! ? Icons.check_circle : Icons.cancel,
                                                color: _currentAnswerCorrect! ? AppTheme.successGreen : AppTheme.errorRed,
                                                size: 48,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _currentAnswerCorrect! ? l10n.quizAnswerCorrect : l10n.quizAnswerIncorrect,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: _currentAnswerCorrect! ? AppTheme.successGreen : AppTheme.errorRed,
                                                  ),
                                                ),
                                              ),
                                              FilledButton(
                                                onPressed: _continueAfterFeedback,
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: _currentAnswerCorrect! ? AppTheme.successGreen : AppTheme.errorRed,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                ),
                                                child: Text(l10n.quizContinue),
                                              ),
                                            ],
                                          ),
                                          // Explanation area (below main row)
                                          if ((_questions[_currentPage].getExplanation(_currentQuestionLanguage) ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _showExplanation = !_showExplanation;
                                                    });
                                                  },
                                                  icon: Icon(_showExplanation ? Icons.expand_less : Icons.expand_more),
                                                  label: Text(_showExplanation ? l10n.quizHideExplanation : l10n.quizShowExplanation),
                                                ),
                                                const SizedBox(width: 8),
                                                if (_showExplanation)
                                                  Expanded(
                                                    child: Text(
                                                      _questions[_currentPage].getExplanation(_currentQuestionLanguage) ?? '',
                                                      style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              // Bottom Info Row
                              if (!widget.immediateAnswerFeedback || !_showingFeedback)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Theory icon (placeholder)
                                    Icon(
                                      Icons.menu_book_outlined,
                                      color: Colors.grey[600],
                                      size: 28,
                                    ),
                                    
                                    // Question counter
                                    Text(
                                      '${_currentPage + 1} ${l10n.quizSubmitOutOf} ${_questions.length}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    
                                    // Translation button
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {},
                                          borderRadius: BorderRadius.circular(8),
                                          child: Icon(
                                            Icons.expand_more,
                                            color: Colors.grey[600],
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: _showTranslationDialog,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Icon(
                                            Icons.translate,
                                            color: theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ============= BOTTOM ANSWER BUTTONS =============
                      // Hide buttons if already answered in immediate feedback mode
                      if (!(widget.immediateAnswerFeedback && isAnswered))
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildBottomAnswerButton(
                                    context: context,
                                    label: l10n.quizAnswerTrue,
                                    isSelected: isAnswered && selectedAnswer == true,
                                    onTap: () => _answerQuestion(index, true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBottomAnswerButton(
                                    context: context,
                                    label: l10n.quizAnswerFalse,
                                    isSelected: isAnswered && selectedAnswer == false,
                                    onTap: () => _answerQuestion(index, false),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

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
      final l10n = AppLocalizations.of(context)!;
      images.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _showImageDialog(
              question.imageUrl!,
              l10n.quizQuestionImage,
            ),
            child: _buildImageCard(question.imageUrl!),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
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
    final theme = Theme.of(context);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.image_not_supported,
              size: 40,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAnswerButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? (label=="VERO" ? Colors.green[500] : Colors.red[500]) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? (label=="VERO" ? Colors.green[500]! : Colors.red[500]!) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
