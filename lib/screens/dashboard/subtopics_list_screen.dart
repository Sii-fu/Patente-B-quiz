import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/topic.dart';
import '../../models/subtopic.dart';
import '../../utils/theme.dart';
import '../../services/quiz_repository.dart';
import '../../services/repository_provider.dart';
import '../../utils/retry_helper.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/shimmer_loading.dart';
import 'quizzes_list_screen.dart';

class SubtopicsListScreen extends StatefulWidget {
  final Topic topic;
  final Color categoryColor;

  const SubtopicsListScreen({
    super.key,
    required this.topic,
    required this.categoryColor,
  });

  @override
  State<SubtopicsListScreen> createState() => _SubtopicsListScreenState();
}

class _SubtopicsListScreenState extends State<SubtopicsListScreen> {
  late QuizRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  List<Subtopic> _subtopics = [];
  List<Subtopic> _filteredSubtopics = [];
  bool _isLoading = true;
  String? _error;
  String _currentLanguage = 'it';
  Map<int, int> _questionCounts = {}; // subtopicId -> question count
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  void _initializeRepository() {
    _repository = RepositoryProvider.quizRepository;
    _loadSubtopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _currentLanguage = locale.languageCode;
  }

  Future<void> _loadSubtopics() async {
    try {
      setState(() => _isLoading = true);

      // Get all subtopics for this topic
      final subtopicsResponse = await _repository.getSubtopicsByTopic(widget.topic.id);

      final subtopics = subtopicsResponse
          .map((json) => Subtopic.fromJson(json))
          .toList();

      // Get question counts for each subtopic (efficient count-only query)
      final subtopicIds = subtopics.map((s) => s.id).toList();
      if (subtopicIds.isNotEmpty) {
        try {
          // Use batch count method - much faster than fetching all questions
          _questionCounts = await _repository.getQuestionCountsForSubtopics(subtopicIds);
        } catch (e) {
          debugPrint('Error loading question counts: $e');
          // Fallback: set all counts to 0
          _questionCounts = {for (var id in subtopicIds) id: 0};
        }
      }

      setState(() {
        _subtopics = subtopics;
        _filteredSubtopics = subtopics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subtopics: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSubtopics(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubtopics = _subtopics;
      } else {
        _filteredSubtopics = _subtopics.where((subtopic) {
          final nameIt = subtopic.nameIt?.toLowerCase() ?? '';
          final nameEn = subtopic.nameEn?.toLowerCase() ?? '';
          final nameBn = subtopic.nameBn?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nameIt.contains(searchLower) ||
                 nameEn.contains(searchLower) ||
                 nameBn.contains(searchLower);
        }).toList();
      }
    });
  }

  int _getTotalQuestions() {
    return _questionCounts.values.fold(0, (sum, count) => sum + count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.categoryColor,
              widget.categoryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: _isSearching
                    ? Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: l10n.searchQuestions,
                                  hintStyle: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: _filterSubtopics,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _filteredSubtopics = _subtopics;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.topic.getName(_currentLanguage),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_getTotalQuestions()} ${l10n.totalQuestions}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isSearching = true;
                              });
                            },
                          ),
                        ],
                      ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _isLoading
                      ? const ShimmerCardList(
                          itemCount: 6,
                          cardHeight: 110,
                          padding: EdgeInsets.all(20),
                          showImage: true,
                        )
                      : _error != null
                          ? ErrorBoundary(
                              error: _error!,
                              onRetry: _loadSubtopics,
                              showDetails: false,
                            )
                          : _filteredSubtopics.isEmpty
                              ? Center(
                                  child: Text(
                                    _isSearching ? l10n.noResultsFound : l10n.noQuestionsAvailable,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _filteredSubtopics.length,
                                  itemBuilder: (context, index) {
                                    final subtopic = _filteredSubtopics[index];
                                    final questionCount = _questionCounts[subtopic.id] ?? 0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Material(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        elevation: 0,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => QuizzesListScreen(
                                                  topic: widget.topic,
                                                  subtopic: subtopic,
                                                  categoryColor: widget.categoryColor,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                // Subtopic Icon
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: widget.categoryColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.folder_open,
                                                    color: widget.categoryColor,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Subtopic Name and Question Count
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        subtopic.getName(_currentLanguage),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.colorScheme.onSurface,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      // Text(
                                                      //   '$questionCount ${l10n.totalQuestions}',
                                                      //   style: TextStyle(
                                                      //     fontSize: 13,
                                                      //     color: AppTheme.darkGrey.withValues(alpha: 0.6),
                                                      //   ),
                                                      // ),
                                                    ],
                                                  ),
                                                ),
                                                
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
