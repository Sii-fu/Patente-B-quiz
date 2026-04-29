import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/theory_chapter.dart';
import '../../../repositories/homework_repository.dart';
import 'admin_homework_cards_screen.dart';
import 'admin_homework_finalize_screen.dart';
import 'admin_homework_selected_screen.dart';
import 'providers/homework_builder_provider.dart';
import 'widgets/homework_selection_bottom_bar.dart';
import 'widgets/homework_selection_progress_chip.dart';
import 'widgets/homework_target_count_dialog.dart';

class AdminHomeworkChaptersScreen extends StatefulWidget {
  const AdminHomeworkChaptersScreen({super.key});

  @override
  State<AdminHomeworkChaptersScreen> createState() =>
      _AdminHomeworkChaptersScreenState();
}

class _AdminHomeworkChaptersScreenState extends State<AdminHomeworkChaptersScreen> {
  final HomeworkRepository _repository = HomeworkRepository();
  final TextEditingController _searchController = TextEditingController();

  List<TheoryChapter> _chapters = <TheoryChapter>[];
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
    final rows = await _repository.getTheoryChapters();
    if (!mounted) return;
    setState(() {
      _chapters = rows;
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

  Future<void> _openCards(TheoryChapter chapter) async {
    final builder = context.read<HomeworkBuilderProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: builder,
          child: AdminHomeworkCardsScreen(chapter: chapter),
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
        ? _chapters
        : _chapters
            .where((chapter) => chapter.getLocalizedName(lang).toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theory Chapters'),
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
                      hintText: 'Search theory chapter',
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final chapter = filtered[index];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openCards(chapter),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text('${chapter.id}'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        chapter.getLocalizedName(lang),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.w800),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
