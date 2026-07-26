import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../services/quiz_repository.dart';
import '../../services/repository_provider.dart';
import '../../features/quiz/quiz_screen.dart';
import 'custom_quiz_screen.dart';

class TopicModeScreen extends StatefulWidget {
  const TopicModeScreen({super.key});

  @override
  State<TopicModeScreen> createState() => _TopicModeScreenState();
}

class _TopicModeScreenState extends State<TopicModeScreen> {
  late QuizRepository _repository;

  // Quiz Configuration
  int _numberOfQuestions = 30;
  bool _hasTimeLimit = false;
  int _timeLimit = 20; // minutes
  Set<int> _selectedTopicIds = {}; // Empty means all topics
  bool _immediateAnswerFeedback = true;

  List<Map<String, dynamic>> _topics = [];
  bool _isLoadingTopics = true;
  final TextEditingController _customQuestionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _updateTimeLimit();
  }

  void _initializeRepository() {
    _repository = RepositoryProvider.quizRepository;
    _loadTopics();
  }

  @override
  void dispose() {
    _customQuestionController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await _repository.getAllTopics();

      final sortedTopics = List<Map<String, dynamic>>.from(topics)
        ..sort((a, b) {
          final aId = a['id'] as int? ?? 0;
          final bId = b['id'] as int? ?? 0;
          return aId.compareTo(bId);
        });

      setState(() {
        _topics = sortedTopics;
        _isLoadingTopics = false;
      });
    } catch (e) {
      debugPrint('Error loading topics: $e');
      setState(() => _isLoadingTopics = false);
    }
  }

  void _updateTimeLimit() {
    // Formula: 30 questions = 20 minutes, proportional
    setState(() {
      _timeLimit = ((_numberOfQuestions / 30) * 20).round();
    });
  }

  void _showTopicSelector() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final sheetTheme = Theme.of(context);
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: sheetTheme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.topicModeSelectTopics,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: sheetTheme.colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTopicIds.clear();
                          });
                          setModalState(() {});
                        },
                        child: Text(l10n.topicModeSelectAll),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Topics List
                Expanded(
                  child: _isLoadingTopics
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),

                          itemCount: _topics.length,
                          itemBuilder: (context, index) {
                            final topic = _topics[index];
                            final topicId = topic['id'] as int;
                            final isSelected = _selectedTopicIds.contains(
                              topicId,
                            );

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    _selectedTopicIds.add(topicId);
                                  } else {
                                    _selectedTopicIds.remove(topicId);
                                  }
                                });
                                setState(() {});
                              },
                              title: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${index + 1}. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: sheetTheme.colorScheme.onSurface,
                                      ),
                                    ),
                                    TextSpan(
                                      text: topic['name_it'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: sheetTheme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              activeColor: sheetTheme.colorScheme.primary,
                            );
                          },
                        ),
                ),
                // Done Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sheetTheme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.topicModeDone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sheetTheme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQuestionCountPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetTheme = Theme.of(context);
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: sheetTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.topicModeNumberOfQuestions,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: sheetTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children:
                      [10, 20, 30, 40, 50, 60, 70, 80, 90, 100].map((count) {
                        return ListTile(
                          title: Text(
                            '$count ${l10n.topicModeQuestions}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: _numberOfQuestions == count
                              ? Icon(
                                  Icons.check,
                                  color: sheetTheme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _numberOfQuestions = count;
                              _updateTimeLimit();
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList()..add(
                        ListTile(
                          title: TextField(
                            controller: _customQuestionController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.topicModeCustomNumber,
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              final customCount = int.tryParse(value);
                              if (customCount != null && customCount > 0) {
                                setState(() {
                                  _numberOfQuestions = customCount;
                                  _updateTimeLimit();
                                });
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar Section
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
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
                        l10n.topicModeTitle,
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
                  margin: const EdgeInsets.only(
                    top: 20,
                    left: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
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
                              l10n.topicModeQuizConfiguration,
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
                              l10n.topicModeConfigureQuiz,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Configuration Items
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildConfigRow(
                                context: context,
                                icon: Icons.quiz,
                                title: l10n.topicModeNumberOfQuestions,
                                value:
                                    '$_numberOfQuestions ${l10n.topicModeQuestions}',
                                onTap: _showQuestionCountPicker,
                              ),
                              const SizedBox(height: 16),
                              _buildConfigRow(
                                context: context,
                                icon: Icons.access_time,
                                title: l10n.topicModeTimeLimit,
                                value: _hasTimeLimit
                                    ? '$_timeLimit ${l10n.topicModeMinutes}'
                                    : l10n.noTimeLimit,
                                onTap: () {
                                  setState(() {
                                    _hasTimeLimit = !_hasTimeLimit;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildConfigRow(
                                context: context,
                                icon: Icons.topic,
                                title: l10n.topicModeTopics,
                                value: _selectedTopicIds.isEmpty
                                    ? l10n.topicModeAllTopics
                                    : '${_selectedTopicIds.length} ${l10n.topicModeSelectedTopics}',
                                onTap: _showTopicSelector,
                              ),
                              const SizedBox(height: 16),
                              _buildConfigRow(
                                context: context,
                                icon: Icons.feedback,
                                title: l10n.feedbackType,
                                value: _immediateAnswerFeedback
                                    ? l10n.topicModeImmediateFeedback
                                    : l10n.feedbackAtEnd,
                                onTap: () {
                                  setState(() {
                                    _immediateAnswerFeedback =
                                        !_immediateAnswerFeedback;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
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
                                  builder: (context) => CustomQuizScreen(
                                    numberOfQuestions: _numberOfQuestions,
                                    hasTimeLimit: _hasTimeLimit,
                                    timeLimit: _timeLimit,
                                    selectedTopicIds: _selectedTopicIds
                                        .toList(),
                                    immediateAnswerFeedback:
                                        _immediateAnswerFeedback,
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
                              child: SizedBox(
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
        ),
      ),
    );
  }

  Widget _buildConfigRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
