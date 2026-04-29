import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/question.dart';
import '../../../models/theory_card.dart';
import '../../../repositories/homework_repository.dart';
import '../../../utils/theme.dart';
import 'admin_homework_finalize_screen.dart';
import 'admin_homework_selected_screen.dart';
import 'providers/homework_builder_provider.dart';
import 'widgets/homework_selection_bottom_bar.dart';
import 'widgets/homework_selection_progress_chip.dart';
import 'widgets/homework_target_count_dialog.dart';

class AdminHomeworkQuizzesScreen extends StatefulWidget {
  const AdminHomeworkQuizzesScreen({
    super.key,
    required this.card,
  });

  final TheoryCard card;

  @override
  State<AdminHomeworkQuizzesScreen> createState() =>
      _AdminHomeworkQuizzesScreenState();
}

class _AdminHomeworkQuizzesScreenState extends State<AdminHomeworkQuizzesScreen> {
  static const int _pageSize = 60;
  final HomeworkRepository _repository = HomeworkRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Question> _questions = <Question>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
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
        _scrollController.position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    if (widget.card.subtopicId == null) {
      setState(() {
        _questions = <Question>[];
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasMore = true;
      _questions = <Question>[];
    });

    final firstPage = await _repository.getQuestionsBySubtopicPaged(
      subtopicId: widget.card.subtopicId!,
      searchQuery: _searchController.text,
      limit: _pageSize,
      offset: 0,
    );

    if (!mounted) return;
    setState(() {
      _questions = firstPage..sort((a, b) => a.id.compareTo(b.id));
      _hasMore = firstPage.length >= _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || widget.card.subtopicId == null) {
      return;
    }

    setState(() => _isLoadingMore = true);
    final nextPage = await _repository.getQuestionsBySubtopicPaged(
      subtopicId: widget.card.subtopicId!,
      searchQuery: _searchController.text,
      limit: _pageSize,
      offset: _questions.length,
    );

    if (!mounted) return;
    setState(() {
      _questions.addAll(nextPage);
      _questions.sort((a, b) => a.id.compareTo(b.id));
      _hasMore = nextPage.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _editTarget() async {
    final builder = context.read<HomeworkBuilderProvider>();
    final value = await showHomeworkTargetCountDialog(
      context,
      initialCount: builder.targetCount,
    );
    if (value == null) return;
    builder.setTargetCount(value);
  }

  Future<void> _openSelected() async {
    final builder = context.read<HomeworkBuilderProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: builder,
          child: const AdminHomeworkSelectedScreen(),
        ),
      ),
    );
  }

  Future<void> _continueToFinalize() async {
    final builder = context.read<HomeworkBuilderProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: builder,
          child: const AdminHomeworkFinalizeScreen(),
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _handleToggleQuestion(
    HomeworkBuilderProvider builder,
    Question question,
  ) {
    final alreadySelected = builder.isQuestionSelected(question.id);
    if (!alreadySelected && builder.reachedTarget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target reached (${builder.targetCount}). Remove a quiz to add another one.',
          ),
        ),
      );
      return;
    }
    builder.toggleQuestion(question);
  }

  @override
  Widget build(BuildContext context) {
    final builder = context.watch<HomeworkBuilderProvider>();
    final lang = Localizations.localeOf(context).languageCode;
    final reachedTarget = builder.reachedTarget;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.getLocalizedTitle(lang) ?? 'Quizzes'),
        actions: [
          HomeworkSelectionProgressChip(
            selectedCount: builder.selectedCount,
            targetCount: builder.targetCount,
            onEditTarget: _editTarget,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (reachedTarget)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Target reached! Remove a selected quiz if you want to replace it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quiz question',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadInitial();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onSubmitted: (_) => _loadInitial(),
            ),
          ),
          Expanded(
            child: widget.card.subtopicId == null
                ? const Center(child: Text('This theory card is not linked to a quiz subtopic.'))
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _questions.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _questions.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final q = _questions[index];
                          final selected = builder.isQuestionSelected(q.id);
                          final canTap = selected || !builder.reachedTarget;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45)
                                : null,
                            child: ListTile(
                              title: Text(
                                q.getText(lang),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text.rich(
                                TextSpan(
                                  style: Theme.of(context).textTheme.bodySmall,
                                  children: [
                                    TextSpan(text:'• Answer: '),
                                    TextSpan(
                                      text: q.isTrue ? 'Vero' : 'Falso',
                                      style: TextStyle(
                                        color: q.isTrue
                                            ? AppTheme.successGreen
                                            : AppTheme.errorRed,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                selected
                                    ? Icons.check_circle
                                    : (canTap ? Icons.add_circle_outline : Icons.lock_outline),
                                color: !canTap
                                    ? Theme.of(context).disabledColor
                                    : null,
                              ),
                              onTap: canTap ? () => _handleToggleQuestion(builder, q) : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: HomeworkSelectionBottomBar(
        selectedCount: builder.selectedCount,
        onViewSelected: _openSelected,
        onClearAll: builder.clearAllSelected,
        onContinue: _continueToFinalize,
      ),
    );
  }
}
