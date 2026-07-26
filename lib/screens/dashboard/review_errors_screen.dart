import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_session.dart';
import '../../models/question.dart';
import '../../utils/theme.dart';
import '../../features/quiz/result_review_screen.dart';

class ReviewErrorsScreen extends StatefulWidget {
  const ReviewErrorsScreen({super.key});

  @override
  State<ReviewErrorsScreen> createState() => _ReviewErrorsScreenState();
}

class _ReviewErrorsScreenState extends State<ReviewErrorsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  int _totalCorrectAnswers = 0;
  int _totalErrors = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch all quiz sessions for the user
      final sessions = await _supabase
          .from('quiz_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Calculate totals
      int totalCorrect = 0;
      int totalErrors = 0;

      for (var session in sessions) {
        final errorsCount = session['errors_count'] ?? 0;
        final totalQuestions = session['total_questions'] ?? 30;
        final correctCount = totalQuestions - errorsCount;

        totalCorrect += correctCount as int;
        totalErrors += errorsCount as int;
      }

      setState(() {
        _sessions = List<Map<String, dynamic>>.from(sessions);
        _totalCorrectAnswers = totalCorrect;
        _totalErrors = totalErrors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openSessionReview(Map<String, dynamic> session) async {
    try {
      final sessionId = session['id'];

      // Fetch answers for this session
      final answers = await _supabase
          .from('quiz_answers')
          .select('question_id, selected_true, is_correct')
          .eq('session_id', sessionId);

      // Fetch all questions for this session
      final questionIds = answers.map((a) => a['question_id']).toList();
      final questionsData = await _supabase
          .from('questions')
          .select('*, subtopics(*)')
          .inFilter('id', questionIds);

      // Build Question objects and userAnswers map
      List<Question> questions = [];
      Map<int, bool> userAnswers = {};

      for (int i = 0; i < questionsData.length; i++) {
        final qData = questionsData[i];
        final answer = answers.firstWhere(
          (a) => a['question_id'] == qData['id'],
        );

        questions.add(Question.fromJson(qData));
        userAnswers[i] = answer['selected_true'];
      }

      final errorsCount = session['errors_count'] ?? 0;
      final totalQuestions = session['total_questions'] ?? 30;
      final correctCount = totalQuestions - errorsCount;
      final isPassed = session['is_passed'] ?? false;
      final duration = session['duration_seconds'] ?? 0;

      // Navigate to review screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultReviewScreen(
              questions: questions,
              userAnswers: userAnswers,
              correctCount: correctCount,
              errorsCount: errorsCount,
              isPassed: isPassed,
              durationSeconds: duration,
              quizMode: QuizMode.reviewErrors,
              showOnlyErrors: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error opening session review: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading session: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar Section with gradient background
              Container(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.reviewErrorsTitle,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : _sessions.isEmpty
                      ? _buildEmptyState(l10n)
                      : Container(
                          margin: const EdgeInsets.only(
                            top: 0,
                            left: 16,
                            right: 16,
                            bottom: 0,
                          ),
                          child: Column(
                            children: [
                              // Summary Card
                              _buildSummaryCard(),

                              const SizedBox(height: 16),

                              // Sessions List
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _sessions.length,
                                  itemBuilder: (context, index) {
                                    return _buildSessionCard(
                                      _sessions[index],
                                      index,
                                    );
                                  },
                                ),
                              ),
                            ],
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz,
                size: 80,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.reviewErrorsNoErrors,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalCorrectAnswers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
              Text(
                '${l10n.reviewErrorsSession} #${_sessions.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalErrors',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              Text(
                l10n.reviewErrorsErrors,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, int index) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final errorsCount = session['errors_count'] ?? 0;
    final totalQuestions = session['total_questions'] ?? 30;
    final isPassed = session['is_passed'] ?? false;
    final createdAt = DateTime.parse(session['created_at']);
    final durationSeconds = session['duration_seconds'] ?? 0;
    final durationMinutes = (durationSeconds / 60).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _openSessionReview(session);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.reviewErrorsSession} #${_sessions.length - index}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$errorsCount ${l10n.reviewErrorsErrors}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tempo: ${durationMinutes}:${(durationSeconds % 60).toString().padLeft(2, '0')} min',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
