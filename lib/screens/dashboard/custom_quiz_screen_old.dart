import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  const CustomQuizScreen({
    super.key,
    required this.numberOfQuestions,
    required this.hasTimeLimit,
    required this.timeLimit,
    required this.selectedTopicIds,
    required this.immediateAnswerFeedback,
  });

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> {
  final PageController _pageController = PageController();
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
    _ttsHelper.stop();
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

      // Use the new fetchCustomQuiz method from QuizService
      final questions = await _quizService.fetchCustomQuiz(
        numberOfQuestions: widget.numberOfQuestions,
        selectedTopicIds: widget.selectedTopicIds,
      );

      setState(() {
        _questions = questions;
        _isLoading = false;
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
      // Show immediate feedback card
      setState(() {
        _showingFeedback = true;
        _currentAnswerCorrect = isCorrect;
        _showExplanation = false;
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
    setState(() {
      _showingFeedback = false;
      _currentAnswerCorrect = null;
      _showExplanation = false;
    });

    // Advance to next question
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.profileCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryBrandBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.tertiary),
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
    
    final question = _questions[_currentPage];
    final text = question.getText(_currentQuestionLanguage);
    
    // Use TtsHelper with robust language handling
    final success = await _ttsHelper.speak(text, _currentQuestionLanguage);
    
    // Show feedback
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
        backgroundColor: success ? null : Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
                  label: const Text('Go Back'),
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ============= TOP BAR =============
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // Back Button
                    InkWell(
                      onTap: _showBackConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Question Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${_questions.length}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Timer (conditional) - now takes remaining space
                    if (widget.hasTimeLimit) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: _secondsRemaining < 60
                                ? theme.colorScheme.error.withValues(alpha: 0.9)
                                : theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: theme.colorScheme.onPrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_secondsRemaining),
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Spacer to push submit button to the right
                    if (!widget.hasTimeLimit) const Spacer(),
                    
                    const SizedBox(width: 16),
                    
                    // Submit Button
                    InkWell(
                      onTap: _showSubmitConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // ============= SWIPEABLE CONTENT AREA =============
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _showingFeedback = false;
                      _currentAnswerCorrect = null;
                      _showExplanation = false;
                    });
                  },
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    final subtopic = question.subtopic;
                    final isAnswered = _userAnswers.containsKey(index);
                    final selectedAnswer = _userAnswers[index];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Subtopic Badge (if available)
                          if (subtopic != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.category, color: theme.colorScheme.onPrimary, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      subtopic.getName(_currentQuestionLanguage),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Main Question Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Question Text
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        question.getText(_currentQuestionLanguage),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _speakQuestion,
                                      icon: const Icon(Icons.volume_up),
                                      color: theme.colorScheme.primary,
                                      iconSize: 28,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Language Buttons
                                _buildLanguageButtons(),

                                const SizedBox(height: 20),

                                // Images Section
                                if (subtopic?.imageUrl != null || question.imageUrl != null)
                                  _buildImageSection(question, subtopic),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Immediate Feedback Card (if showing)
                          if (widget.immediateAnswerFeedback && _showingFeedback && _currentAnswerCorrect != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _currentAnswerCorrect! 
                                    ? AppTheme.successGreen 
                                    : AppTheme.errorRed,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_currentAnswerCorrect! 
                                        ? AppTheme.successGreen 
                                        : AppTheme.errorRed).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _currentAnswerCorrect! 
                                        ? Icons.check_circle 
                                        : Icons.cancel,
                                    color: theme.colorScheme.onPrimary,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _currentAnswerCorrect! 
                                        ? l10n.customQuizCorrectAnswer 
                                        : l10n.customQuizIncorrectAnswer,
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Show/Hide Explanation Button
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showExplanation = !_showExplanation;
                                      });
                                    },
                                    icon: Icon(
                                      _showExplanation ? Icons.visibility_off : Icons.info_outline,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    label: Text(
                                      _showExplanation 
                                          ? l10n.customQuizHideExplanation 
                                          : l10n.customQuizShowExplanation,
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: theme.colorScheme.onPrimary, width: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  
                                  // Explanation Text (if shown)
                                  if (_showExplanation) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        question.getExplanation(_currentQuestionLanguage) ?? 
                                            l10n.customQuizNoExplanation,
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _continueAfterFeedback,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.onPrimary,
                                        foregroundColor: _currentAnswerCorrect! 
                                            ? AppTheme.successGreen 
                                            : AppTheme.errorRed,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            l10n.customQuizContinue,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Answer Buttons (hidden during feedback)
                            if (!_showingFeedback) ...[
                            Row(
                              children: [
                              Expanded(
                                child: _buildAnswerButton(
                                context: context,
                                label: l10n.quizTrue,
                                icon: Icons.check,
                                color: AppTheme.successGreen,
                                isSelected: isAnswered && selectedAnswer == true,
                                onTap: () => _answerQuestion(index, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAnswerButton(
                                context: context,
                                label: l10n.quizFalse,
                                icon: Icons.close,
                                color: AppTheme.errorRed,
                                isSelected: isAnswered && selectedAnswer == false,
                                onTap: () => _answerQuestion(index, false),
                                ),
                              ),
                              ],
                            ),
                            ],

                          const SizedBox(height: 32),
                        ],
                      ),
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

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary,
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

  Widget _buildLanguageButtons() {
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
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _currentQuestionLanguage = langCode;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              _getLanguageShortName(langCode),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerButton({
    required BuildContext context,
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? color : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.onPrimary : color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
