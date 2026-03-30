import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../utils/theme.dart';
import 'result_review_screen.dart';

/// Page 2: Quiz Result - Gamified Score with Breakdown
/// Engaging presentation with donut chart and score breakdown
class ResultGamifiedScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, bool> userAnswers;
  final int correctCount;
  final int errorsCount;
  final bool isPassed;
  final int durationSeconds;
  final QuizMode quizMode;

  const ResultGamifiedScreen({
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
  State<ResultGamifiedScreen> createState() => _ResultGamifiedScreenState();
}

class _ResultGamifiedScreenState extends State<ResultGamifiedScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _statsController;
  late Animation<double> _correctAnimation;
  late Animation<double> _incorrectAnimation;

  @override
  void initState() {
    super.initState();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _correctAnimation = Tween<double>(
      begin: 0.0,
      end: widget.correctCount / widget.questions.length,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));

    final skippedCount = widget.questions.length -
        widget.userAnswers.length;
    _incorrectAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.errorsCount + skippedCount) / widget.questions.length,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));

    _chartController.forward();
    _statsController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  int get _skippedCount =>
      widget.questions.length - widget.userAnswers.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBrandBlue,
              AppTheme.primaryBrandBlue.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Congratulations
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: theme.colorScheme.onPrimary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMPLIMENTI!!!',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                color: Colors.amber[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main White Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Star Icon
                              Icon(
                                Icons.star,
                                color: AppTheme.primaryBrandGreen,
                                size: 40,
                              ),

                              const SizedBox(height: 24),

                              // Donut Chart
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: AnimatedBuilder(
                                  animation: _chartController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: DonutChartPainter(
                                        correctPercentage: _correctAnimation.value,
                                        incorrectPercentage: _incorrectAnimation.value,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.star,
                                          color: AppTheme.primaryBrandBlue,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Score Summary
                              Text(
                                '${widget.correctCount}/${widget.questions.length} Corrette',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Breakdown Stats
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatCircle(
                                    'Corrette',
                                    widget.correctCount,
                                    widget.questions.length,
                                    AppTheme.successGreen,
                                  ),
                                  _buildStatCircle(
                                    '${((widget.errorsCount / widget.questions.length) * 100).round()}%',
                                    widget.errorsCount,
                                    widget.questions.length,
                                    AppTheme.errorRed,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Buttons
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // View Errors Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
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
                                        showOnlyErrors: true,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBrandBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'VEDI ERRORI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Share Result Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  // Share functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBrandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'CONDIVIDI RISULTATO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCircle(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final theme = Theme.of(context);
    final percentage = (value / total * 100).round();

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _statsController,
        curve: Curves.elasticOut,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: value / total,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for donut chart
class DonutChartPainter extends CustomPainter {
  final double correctPercentage;
  final double incorrectPercentage;

  DonutChartPainter({
    required this.correctPercentage,
    required this.incorrectPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 30.0;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFFE0E0E0) // theme-appropriate grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Correct answers arc (green)
    final correctPaint = Paint()
      ..color = AppTheme.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 / 2, // Start from top
      correctPercentage * 2 * 3.14159,
      false,
      correctPaint,
    );

    // Incorrect answers arc (blue/red)
    final incorrectPaint = Paint()
      ..color = AppTheme.primaryBrandBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 / 2 + correctPercentage * 2 * 3.14159,
      incorrectPercentage * 2 * 3.14159,
      false,
      incorrectPaint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => true;
}
