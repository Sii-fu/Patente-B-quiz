import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/vocabulary_word.dart';
import '../../repositories/vocabulary_repository.dart';
import '../../services/tts_helper.dart';
import '../../utils/theme.dart';
import 'word_questions_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  final VocabularyRepository _repo = VocabularyRepository();
  final TtsHelper _ttsHelper = TtsHelper();
  final TextEditingController _searchController = TextEditingController();

  List<VocabularyWord> _allWords = [];
  List<VocabularyWord> _filteredWords = [];
  Set<int> _starredIds = {};
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _ttsHelper.init();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ttsHelper.stop();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final results = await Future.wait([
        _repo.getVocabulary(),
        _repo.getStarredIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _allWords = results[0] as List<VocabularyWord>;
        _starredIds = results[1] as Set<int>;
        _filteredWords = List.from(_allWords);
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredWords = List.from(_allWords);
      } else {
        _filteredWords = _allWords.where((w) {
          return w.wordIt.toLowerCase().contains(query) ||
              (w.translationEn?.toLowerCase().contains(query) ?? false) ||
              (w.translationBn?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _toggleStar(int wordId) async {
    HapticFeedback.selectionClick();
    final newState = await _repo.toggleStar(wordId);
    setState(() {
      if (newState) {
        _starredIds.add(wordId);
      } else {
        _starredIds.remove(wordId);
      }
    });
  }

  Future<void> _speakWord(String word) async {
    HapticFeedback.lightImpact();
    await _ttsHelper.speak(word, 'it');
  }

  List<VocabularyWord> get _displayList {
    final source =
        _tabController.index == 1 ? _filteredWords.where((w) => _starredIds.contains(w.id)).toList() : _filteredWords;
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.vocabTitle,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_allWords.length} ${l10n.vocabWords}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              // ── Search Bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    // Solid surface colour so text/icons are always readable
                    // on the gradient in both light and dark modes.
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: l10n.vocabSearchHint,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: theme.colorScheme.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // ── Tabs ────────────────────────────────────────────────────     
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onPrimary,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: l10n.vocabAllWords),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.vocabStarred),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: theme.colorScheme.primary),
                              const SizedBox(height: 16),
                              Text(l10n.vocabLoading),
                            ],
                          ),
                        )
                      : _error != null
                          ? _buildErrorView(l10n, theme)
                          : _buildWordList(l10n, theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.vocabError,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.vocabRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList(AppLocalizations l10n, ThemeData theme) {
    final list = _displayList;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 1
                  ? l10n.vocabNoStarred
                  : l10n.vocabNoResults,
              style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) =>
          _buildWordCard(list[index], l10n, theme),
    );
  }

  Widget _buildWordCard(
      VocabularyWord word, AppLocalizations l10n, ThemeData theme) {
    final isStarred = _starredIds.contains(word.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStarred
              ? Colors.amber.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isStarred ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: word + speaker + star ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.wordIt,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Speaker
                IconButton(
                  onPressed: () => _speakWord(word.wordIt),
                  icon: Icon(Icons.volume_up,
                      color: theme.colorScheme.primary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // Star
                IconButton(
                  onPressed: () => _toggleStar(word.id),
                  icon: Icon(
                    isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isStarred ? Colors.amber : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),

            // ── Translations ─────────────────────────────────────────────
            if (word.translationEn != null || word.translationBn != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
            ],
            if (word.translationEn != null)
              _buildTranslationRow(
                flag: '🇬🇧',
                text: word.translationEn!,
                theme: theme,
              ),
            if (word.translationBn != null) ...[
              const SizedBox(height: 4),
              _buildTranslationRow(
                flag: '🇧🇩',
                text: word.translationBn!,
                theme: theme,
              ),
            ],

            // ── See Exam Questions ────────────────────────────────────────
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordQuestionsScreen(targetWord: word.wordIt),
                    ),
                  );
                },
                icon: const Text('🔍', style: TextStyle(fontSize: 14)),
                label: Text(l10n.vocabSeeQuestions),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationRow({
    required String flag,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(flag, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
