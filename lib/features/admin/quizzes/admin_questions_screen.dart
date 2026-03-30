import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'quiz_edit_screen.dart';

/// Admin Questions Screen
/// Shows all questions for a subtopic with edit/add functionality
class AdminQuestionsScreen extends StatefulWidget {
  final int subtopicId;
  final String subtopicName;
  final Color categoryColor;

  const AdminQuestionsScreen({
    super.key,
    required this.subtopicId,
    required this.subtopicName,
    required this.categoryColor,
  });

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await _adminRepository.getQuestionsBySubtopic(widget.subtopicId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _filteredQuestions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterQuestions(String query) {
    if (query.isEmpty) {
      setState(() => _filteredQuestions = _questions);
    } else {
      setState(() {
        _filteredQuestions = _questions.where((q) {
          final textIt = (q['text_it'] ?? '').toString().toLowerCase();
          final textEn = (q['text_en'] ?? '').toString().toLowerCase();
          return textIt.contains(query.toLowerCase()) ||
                 textEn.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  String _getLocalizedText(Map<String, dynamic> item, String langCode) {
    switch (langCode) {
      case 'en':
        return item['text_en'] ?? item['text_it'] ?? '';
      case 'bn':
        return item['text_bn'] ?? item['text_it'] ?? '';
      default:
        return item['text_it'] ?? '';
    }
  }

  Future<void> _navigateToEdit([Map<String, dynamic>? question]) async {
    HapticFeedback.mediumImpact();
    
    // Get subtopics list for the dropdown
    final subtopics = await _adminRepository.getSubtopics();
    
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizEditScreen(
          question: question,
          subtopics: subtopics,
          preselectedSubtopicId: widget.subtopicId,
        ),
      ),
    );

    if (result == true) {
      _loadQuestions();
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
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
      final success = await _adminRepository.deleteQuestion(question['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminQuestionDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _loadQuestions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subtopicName),
        backgroundColor: widget.categoryColor.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddQuestion),
        backgroundColor: widget.categoryColor,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchQuestions,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterQuestions('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: _filterQuestions,
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredQuestions.length} ${l10n.totalQuestions}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Questions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuestions,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : _filteredQuestions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noQuestionsAvailable,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuestions,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 100,
                              ),
                              itemCount: _filteredQuestions.length,
                              itemBuilder: (context, index) {
                                final question = _filteredQuestions[index];
                                final isTrue = question['is_true'] as bool? ?? false;
                                final hasImage = question['image_url'] != null &&
                                    (question['image_url'] as String).isNotEmpty;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _navigateToEdit(question),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header row
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isTrue
                                                      ? Colors.green.withOpacity(0.2)
                                                      : Colors.red.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isTrue ? l10n.quizTrue : l10n.quizFalse,
                                                  style: TextStyle(
                                                    color: isTrue ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '#${question['id']}',
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () => _navigateToEdit(question),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: l10n.adminEdit,
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                onPressed: () => _deleteQuestion(question),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: l10n.adminDelete,
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Question content row
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Image thumbnail if available
                                              if (hasImage) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: question['image_url'] as String,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: theme.colorScheme.surfaceContainerHighest,
                                                      child: const Icon(Icons.image, size: 24),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: theme.colorScheme.surfaceContainerHighest,
                                                      child: const Icon(Icons.broken_image, size: 24),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                              ],
                                              
                                              // Question text
                                              Expanded(
                                                child: Text(
                                                  _getLocalizedText(question, langCode),
                                                  style: theme.textTheme.bodyMedium,
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
    );
  }
}
