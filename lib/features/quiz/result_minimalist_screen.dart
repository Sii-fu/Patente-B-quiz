import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../utils/theme.dart';
import '../../providers/language_provider.dart';
import 'result_review_screen.dart';

/// Page 1: Quiz Result - Minimalist Score Display
/// Clean, concise summary focusing on performance percentage
class ResultMinimalistScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, bool> userAnswers;
  final int correctCount;
  final int errorsCount;
  final bool isPassed;
  final int durationSeconds;
  final QuizMode quizMode;

  const ResultMinimalistScreen({
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
  State<ResultMinimalistScreen> createState() => _ResultMinimalistScreenState();
}

class _ResultMinimalistScreenState extends State<ResultMinimalistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.correctCount / widget.questions.length,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _scorePercentage =>
      ((widget.correctCount / widget.questions.length) * 100).round();

  String _getPerformanceText(AppLocalizations l10n) {
    if (_scorePercentage >= 90) return l10n.resultExcellent;
    if (_scorePercentage >= 80) return l10n.resultGreat;
    if (_scorePercentage >= 70) return l10n.resultGood;
    if (_scorePercentage >= 60) return l10n.resultSufficient;
    return l10n.resultNeedsImprovement;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.isPassed 
                ? AppTheme.primaryBrandBlue
                : AppTheme.errorRed.withOpacity(0.5),
              widget.isPassed
                ? AppTheme.primaryBrandGreen
                : AppTheme.errorRed.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Compact Header with Trophy Icon
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        widget.isPassed ? Icons.emoji_events : Icons.no_accounts,
                        color: Colors.amber[300],
                        size: 50,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance layout
                  ],
                ),
              ),

              // Main Content Area (no scrolling needed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pass/Fail Badge + Score Ring Combined
                      Column(
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isPassed ? Icons.check_circle : Icons.cancel,
                                  color: widget.isPassed ? AppTheme.successGreen : AppTheme.errorRed,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isPassed ? l10n.resultPromoted : l10n.resultRejected,
                                  style: TextStyle(
                                    color: widget.isPassed ? AppTheme.successGreen : AppTheme.errorRed,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Smaller Score Ring (120x120)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: _progressAnimation.value,
                                      strokeWidth: 10,
                                      backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                    ),
                                  );
                                },
                              ),
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(_progressAnimation.value * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                                      Text(

                                        _getPerformanceText(l10n),
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                        ),
                                      ),
                        ],
                      ),

                      // Gamified Stats Row (3 circles)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Correct Answers - styled text
                          ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              ),
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.successGreen, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                '${widget.correctCount}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.successGreen,
                                  letterSpacing: 0.5,
                                ),
                                ),
                              ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.resultCorrectAnswers.split(' ')[0],
                              style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary.withOpacity(0.95),
                              letterSpacing: 0.8,
                              ),
                            ),
                            ],
                          ),
                          ),

                          // Total Time - styled text
                          ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
                              ),
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer, color: AppTheme.primaryBrandBlue, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBrandBlue,
                                ),
                                ),
                              ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.resultTotalTime.split(':')[0],
                              style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary.withOpacity(0.95),
                              letterSpacing: 0.8,
                              ),
                            ),
                            ],
                          ),
                          ),

                          // Errors - styled text
                          ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
                              ),
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel, color: AppTheme.errorRed, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                '${widget.errorsCount}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.errorRed,
                                  letterSpacing: 0.5,
                                ),
                                ),
                              ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.resultErrors.split(':')[0],
                              style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary.withOpacity(0.95),
                              letterSpacing: 0.8,
                              ),
                            ),
                            ],
                          ),
                          ),
                        ],
                        ),

                      
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Review Quiz Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultReviewScreen(
                                questions: widget.questions,
                                userAnswers: widget.userAnswers,
                                correctCount: widget.correctCount,
                                errorsCount: widget.errorsCount,
                                isPassed: widget.isPassed,
                                durationSeconds: widget.durationSeconds,
                                quizMode: widget.quizMode,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.resultReviewQuiz,
                          style: const TextStyle(
                            color: AppTheme.primaryBrandBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom Button Row
                    Row(
                      children: [
                        // New Quiz Button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.lightGrey,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.resultNew,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.lightGrey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Exit Button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBrandGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.resultExit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
  }

  Widget _buildStatCircle(IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
