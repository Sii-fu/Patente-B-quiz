import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_session.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../utils/theme.dart';

class ExamModeScreen extends StatelessWidget {
  const ExamModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
        child: Column(
          children: [
            // AppBar Section with gradient background
            Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.examModeStart,
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
            
            // Main Content Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Column(
                        children: [
                          Text(
                            l10n.examModeQuizTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.examModeReadyMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Info Items
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoRow(
                              context: context,
                              icon: Icons.subject,
                              text: l10n.examModeQuestions,
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              context: context,
                              icon: Icons.access_time,
                              text: l10n.examModeTimeLimit,
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              context: context,
                              icon: Icons.check_box_outlined,
                              text: l10n.examModeAllTopics,
                              hasArrow: true,
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              context: context,
                              icon: Icons.warning_amber_outlined,
                              text: l10n.examModeMinCorrect,
                              hasArrow: true,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.examModeSimulation,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Start Button
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizScreen(
                                  isExamMode: true,
                                  quizMode: QuizMode.simulation,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Container(
                              height: 60,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.examModeStartButton,
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: theme.colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    bool hasArrow = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 28,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
