import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'quiz_edit_screen.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _subtopics = [];
  List<Map<String, dynamic>> _filteredSubtopics = [];
  int? _selectedTopicId;
  int? _selectedSubtopicId;
  bool _isLoading = true;
  String? _error;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreQuestions();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topics = await _adminRepository.getTopics();
      final subtopics = await _adminRepository.getSubtopics();
      final questions = await _adminRepository.getQuestions(
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _topics = topics;
        _subtopics = subtopics;
        _filteredSubtopics = subtopics;
        _questions = questions;
        _isLoading = false;
        _hasMore = questions.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (!_hasMore || _isLoading) return;

    final newQuestions = await _adminRepository.getQuestions(
      subtopicId: _selectedSubtopicId,
      searchQuery: _searchController.text,
      limit: _pageSize,
      offset: _questions.length,
    );

    if (!mounted) return;
    setState(() {
      _questions.addAll(newQuestions);
      _hasMore = newQuestions.length >= _pageSize;
    });
  }

  Future<void> _searchQuestions() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    final questions = await _adminRepository.getQuestions(
      subtopicId: _selectedSubtopicId,
      searchQuery: _searchController.text,
      limit: _pageSize,
      offset: 0,
    );

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _isLoading = false;
      _hasMore = questions.length >= _pageSize;
    });
  }

  void _onSubtopicChanged(int? subtopicId) {
    setState(() {
      _selectedSubtopicId = subtopicId;
    });
    _searchQuestions();
  }

  Future<void> _navigateToEdit(Map<String, dynamic>? question) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizEditScreen(
          question: question,
          subtopics: _subtopics,
        ),
      ),
    );

    if (result == true) {
      _searchQuestions();
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteQuestion),
        content: Text(l10n.adminDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminRepository.deleteQuestion(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminQuestionDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _searchQuestions();
      }
    }
  }

  void _showSearchFilters() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SearchFilterSheet(
        topics: _topics,
        subtopics: _subtopics,
        selectedTopicId: _selectedTopicId,
        selectedSubtopicId: _selectedSubtopicId,
        initialSearchQuery: _searchController.text,
        onApply: (topicId, subtopicId, searchQuery) {
          setState(() {
            _selectedTopicId = topicId;
            _selectedSubtopicId = subtopicId;
            _searchController.text = searchQuery;
          });
          _searchQuestions();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminQuizManagement),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchFilters,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddQuestion),
      ),
      body: Column(
        children: [
          // Active Filters Display
          if (_selectedTopicId != null || _selectedSubtopicId != null || _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedTopicId = null;
                        _selectedSubtopicId = null;
                        _searchController.clear();
                        _filteredSubtopics = _subtopics;
                      });
                      _searchQuestions();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_questions.length} ${l10n.totalQuestions}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Question List
          Expanded(
            child: _buildQuestionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noQuestionsAvailable,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _questions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildQuestionCard(_questions[index]);
        },
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final id = question['id'] as int;
    final textIt = question['text_it'] ?? '';
    final isTrue = question['is_true'] == true;
    final imageUrl = question['image_url'];
    final subtopic = question['subtopics'];
    final subtopicName = subtopic?['name_it'] ?? '';
    final topicName = subtopic?['topics']?['name_it'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(question),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$id',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTrue 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isTrue ? l10n.quizTrue : l10n.quizFalse,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isTrue ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.image, size: 16, color: Colors.grey),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteQuestion(id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Question Text
              Text(
                textIt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              
              // Question Image
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '$imageUrl',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Topic Info
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$topicName > $subtopicName',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_selectedTopicId != null) {
      final topic = _topics.firstWhere(
        (t) => t['id'] == _selectedTopicId,
        orElse: () => {},
      );
      if (topic.isNotEmpty) {
        parts.add(topic['name_it'] ?? '');
      }
    }
    if (_selectedSubtopicId != null) {
      final subtopic = _subtopics.firstWhere(
        (s) => s['id'] == _selectedSubtopicId,
        orElse: () => {},
      );
      if (subtopic.isNotEmpty) {
        parts.add(subtopic['name_it'] ?? '');
      }
    }
    if (_searchController.text.isNotEmpty) {
      parts.add('"${_searchController.text}"');
    }
    return parts.join(' • ');
  }
}

class _SearchFilterSheet extends StatefulWidget {
  final List<Map<String, dynamic>> topics;
  final List<Map<String, dynamic>> subtopics;
  final int? selectedTopicId;
  final int? selectedSubtopicId;
  final String initialSearchQuery;
  final Function(int?, int?, String) onApply;

  const _SearchFilterSheet({
    required this.topics,
    required this.subtopics,
    required this.selectedTopicId,
    required this.selectedSubtopicId,
    required this.initialSearchQuery,
    required this.onApply,
  });

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late TextEditingController _searchController;
  int? _selectedTopicId;
  int? _selectedSubtopicId;
  List<Map<String, dynamic>> _filteredSubtopics = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedTopicId = widget.selectedTopicId;
    _selectedSubtopicId = widget.selectedSubtopicId;
    _filterSubtopics();
  }

  void _filterSubtopics() {
    if (_selectedTopicId == null) {
      _filteredSubtopics = widget.subtopics;
    } else {
      _filteredSubtopics = widget.subtopics
          .where((s) => s['topic_id'] == _selectedTopicId)
          .toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.filter_alt),
                const SizedBox(width: 8),
                Text(
                  l10n.adminSearchFilters,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Field
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchQuestions,
                hintText: l10n.adminEnterKeyword,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Topic Dropdown
            DropdownButtonFormField<int?>(
              value: _selectedTopicId,
              decoration: InputDecoration(
                labelText: l10n.adminFilterByTopic,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.filterAll),
                ),
                ...widget.topics.map((topic) {
                  return DropdownMenuItem<int?>(
                    value: topic['id'] as int,
                    child: Text(
                      topic['name_it'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTopicId = value;
                  _selectedSubtopicId = null; // Reset subtopic when topic changes
                  _filterSubtopics();
                });
              },
            ),
            const SizedBox(height: 16),

            // Subtopic Dropdown
            DropdownButtonFormField<int?>(
              value: _selectedSubtopicId,
              decoration: InputDecoration(
                labelText: l10n.adminFilterBySubtopic,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.filterAll),
                ),
                ..._filteredSubtopics.map((subtopic) {
                  return DropdownMenuItem<int?>(
                    value: subtopic['id'] as int,
                    child: Text(
                      subtopic['name_it'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubtopicId = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedTopicId = null;
                        _selectedSubtopicId = null;
                        _filterSubtopics();
                      });
                    },
                    child: Text(l10n.adminClearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onApply(_selectedTopicId, _selectedSubtopicId, _searchController.text);
                    },
                    child: Text(l10n.adminApplyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
