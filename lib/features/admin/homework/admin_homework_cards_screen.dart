import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/theory_card.dart';
import '../../../models/theory_chapter.dart';
import '../../../repositories/homework_repository.dart';
import 'admin_homework_finalize_screen.dart';
import 'admin_homework_quizzes_screen.dart';
import 'admin_homework_selected_screen.dart';
import 'providers/homework_builder_provider.dart';
import 'widgets/homework_selection_bottom_bar.dart';
import 'widgets/homework_selection_progress_chip.dart';
import 'widgets/homework_target_count_dialog.dart';

class AdminHomeworkCardsScreen extends StatefulWidget {
  const AdminHomeworkCardsScreen({
    super.key,
    required this.chapter,
  });

  final TheoryChapter chapter;

  @override
  State<AdminHomeworkCardsScreen> createState() => _AdminHomeworkCardsScreenState();
}

class _AdminHomeworkCardsScreenState extends State<AdminHomeworkCardsScreen> {
  final HomeworkRepository _repository = HomeworkRepository();
  final TextEditingController _searchController = TextEditingController();

  List<TheoryCard> _cards = <TheoryCard>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final rows = await _repository.getTheoryCardsByChapter(widget.chapter.id);
    if (!mounted) return;
    setState(() {
      _cards = rows;
      _isLoading = false;
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

  Future<void> _openQuizzes(TheoryCard card) async {
    final builder = context.read<HomeworkBuilderProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: builder,
          child: AdminHomeworkQuizzesScreen(card: card),
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final builder = context.watch<HomeworkBuilderProvider>();
    final lang = Localizations.localeOf(context).languageCode;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _cards
        : _cards
            .where((card) {
              final title = card.getLocalizedTitle(lang) ?? '';
              final text = card.getLocalizedText(lang);
              return title.toLowerCase().contains(query) ||
                  text.toLowerCase().contains(query);
            })
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.getLocalizedName(lang)),
        actions: [
          HomeworkSelectionProgressChip(
            selectedCount: builder.selectedCount,
            targetCount: builder.targetCount,
            onEditTarget: _editTarget,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search theory card',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final card = filtered[index];
                      final title = card.getLocalizedTitle(lang) ?? 'Theory Card #${card.id}';
                      return Card(
                        child: ListTile(
                          title: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('• Subtopic: ${card.subtopicId ?? '-'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openQuizzes(card),
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
