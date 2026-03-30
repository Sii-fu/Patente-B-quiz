import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'theory_edit_screen.dart';

/// Admin Theory Cards Screen
/// Shows all theory cards for a chapter with edit/add functionality
class AdminTheoryCardsScreen extends StatefulWidget {
  final int chapterId;
  final String chapterName;

  const AdminTheoryCardsScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  State<AdminTheoryCardsScreen> createState() => _AdminTheoryCardsScreenState();
}

class _AdminTheoryCardsScreenState extends State<AdminTheoryCardsScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _filteredCards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _orderOf(Map<String, dynamic> item) {
    final v = item['display_order'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 9999;
    return 9999;
  }

  void _sortByDisplayOrder(List<Map<String, dynamic>> list) {
    list.sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cards = await _adminRepository.getTheoryCardsByChapter(widget.chapterId);
      if (mounted) {
        // Ensure ascending order by display_order (1..n)
        final ordered = List<Map<String, dynamic>>.from(cards);
        _sortByDisplayOrder(ordered);
        setState(() {
          _cards = ordered;
          _filteredCards = ordered;
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

  void _filterCards(String query) {
    if (query.isEmpty) {
      final ordered = List<Map<String, dynamic>>.from(_cards);
      _sortByDisplayOrder(ordered);
      setState(() => _filteredCards = ordered);
    } else {
      final results = _cards.where((c) {
        final titleIt = (c['title_it'] ?? '').toString().toLowerCase();
        final textIt = (c['text_it'] ?? '').toString().toLowerCase();
        return titleIt.contains(query.toLowerCase()) ||
            textIt.contains(query.toLowerCase());
      }).toList();
      _sortByDisplayOrder(results);
      setState(() {
        _filteredCards = results;
      });
    }
  }

  String _getLocalizedTitle(Map<String, dynamic> item, String langCode) {
    switch (langCode) {
      case 'en':
        return item['title_en'] ?? item['title_it'] ?? '';
      case 'bn':
        return item['title_bn'] ?? item['title_it'] ?? '';
      default:
        return item['title_it'] ?? '';
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

  Future<void> _navigateToEdit([Map<String, dynamic>? card]) async {
    HapticFeedback.mediumImpact();

    // Get chapters list for the dropdown and sort ascending by display_order
    final chapters = await _adminRepository.getTheoryChapters();
    final chaptersSorted = List<Map<String, dynamic>>.from(chapters);
    _sortByDisplayOrder(chaptersSorted);

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TheoryEditScreen(
          card: card,
          chapters: chaptersSorted,
          preselectedChapterId: widget.chapterId,
        ),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteTheoryCard),
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
      final success = await _adminRepository.deleteTheoryCard(card['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminTheoryCardDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _loadCards();
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
        title: Text(widget.chapterName),
        backgroundColor: Colors.orange.withOpacity(0.1),
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
        label: Text(l10n.adminAddTheoryCard),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.adminSearchTheory,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCards('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: _filterCards,
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredCards.length} ${l10n.adminTheoryCards}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCards,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : _filteredCards.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.article_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.adminNoTheoryCards,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCards,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 100,
                              ),
                              itemCount: _filteredCards.length,
                              itemBuilder: (context, index) {
                                final card = _filteredCards[index];
                                final title = _getLocalizedTitle(card, langCode);
                                final text = _getLocalizedText(card, langCode);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _navigateToEdit(card),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header row
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.orange.withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '#${card['display_order'] ?? index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon:
                                                    const Icon(Icons.edit, size: 18),
                                                onPressed: () => _navigateToEdit(card),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: l10n.adminEdit,
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 18, color: Colors.red),
                                                onPressed: () => _deleteCard(card),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: l10n.adminDelete,
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          // Title
                                          if (title.isNotEmpty)
                                            Text(
                                              title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                          const SizedBox(height: 8),

                                          // Content preview
                                          Text(
                                            text,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
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
