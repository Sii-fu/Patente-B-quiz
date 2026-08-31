import 'package:flutter/material.dart';
import '../../features/admin/services/admin_repository.dart';
import '../../models/question.dart';

/// Admin-only screen to reorder the questions of a single subtopic
/// (theory card) via drag and drop.
///
/// Pops with `true` when the new order was saved successfully, so the
/// caller can refresh its own list.
class ReorderQuizQuestionsScreen extends StatefulWidget {
  final int subtopicId;

  const ReorderQuizQuestionsScreen({super.key, required this.subtopicId});

  @override
  State<ReorderQuizQuestionsScreen> createState() =>
      _ReorderQuizQuestionsScreenState();
}

class _ReorderQuizQuestionsScreenState
    extends State<ReorderQuizQuestionsScreen> {
  final AdminRepository _adminRepo = AdminRepository();

  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminRepo.getQuestions(
        subtopicId: widget.subtopicId,
        limit: 500,
      );

      if (!mounted) return;
      setState(() {
        _questions = response.map(Question.fromJson).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // ReorderableListView reports an insertion index, which is one too
      // high when an item moves down the list.
      if (newIndex > oldIndex) newIndex -= 1;
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);
    });
  }

  Future<void> _saveOrder() async {
    if (_isSaving || _questions.isEmpty) return;

    setState(() => _isSaving = true);

    final orderedIds = _questions.map((q) => q.id).toList();
    final success = await _adminRepo.reorderQuestions(orderedIds);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz order saved successfully!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save quiz order'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Reorder Quizzes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              // The app theme stretches ElevatedButtons to Size(infinity, 56),
              // which is invalid inside the unbounded width of AppBar.actions.
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: (_isSaving || _isLoading || _questions.isEmpty)
                  ? null
                  : _saveOrder,
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Save Order'),
            ),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No quizzes to reorder',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.surfaceContainerHigh,
          child: Text(
            'Drag the handles to change the quiz order, then tap Save Order.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _questions.length,
            onReorder: _onReorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return _buildQuestionTile(theme, question, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTile(ThemeData theme, Question question, int index) {
    final isTrue = question.isTrue;
    final badgeColor = isTrue ? Colors.green : Colors.red;

    return Card(
      key: ValueKey(question.id),
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.textIt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isTrue ? 'True' : 'False',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
