import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'theory_edit_screen.dart';

class TheoryManagementScreen extends StatefulWidget {
  const TheoryManagementScreen({super.key});

  @override
  State<TheoryManagementScreen> createState() => _TheoryManagementScreenState();
}

class _TheoryManagementScreenState extends State<TheoryManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _theoryCards = [];
  List<Map<String, dynamic>> _chapters = [];
  int? _selectedChapterId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chapters = await _adminRepository.getTheoryChapters();
      final cards = await _adminRepository.getTheoryCards();

      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _theoryCards = cards;
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

  Future<void> _searchCards() async {
    setState(() {
      _isLoading = true;
    });

    final cards = await _adminRepository.getTheoryCards(
      chapterId: _selectedChapterId,
      searchQuery: _searchController.text,
    );

    if (!mounted) return;
    setState(() {
      _theoryCards = cards;
      _isLoading = false;
    });
  }

  void _onChapterChanged(int? chapterId) {
    setState(() {
      _selectedChapterId = chapterId;
    });
    _searchCards();
  }

  Future<void> _navigateToEdit(Map<String, dynamic>? card) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TheoryEditScreen(
          card: card,
          chapters: _chapters,
        ),
      ),
    );

    if (result == true) {
      _searchCards();
    }
  }

  Future<void> _deleteCard(int id) async {
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
      final success = await _adminRepository.deleteTheoryCard(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminTheoryCardDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _searchCards();
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
        chapters: _chapters,
        selectedChapterId: _selectedChapterId,
        initialSearchQuery: _searchController.text,
        onApply: (chapterId, searchQuery) {
          setState(() {
            _selectedChapterId = chapterId;
            _searchController.text = searchQuery;
          });
          _searchCards();
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
        title: Text(l10n.adminTheoryManagement),
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
        label: Text(l10n.adminAddTheoryCard),
      ),
      body: Column(
        children: [
          // Active Filters Display
          if (_selectedChapterId != null || _searchController.text.isNotEmpty)
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
                        _selectedChapterId = null;
                        _searchController.clear();
                      });
                      _searchCards();
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
                  '${_theoryCards.length} ${l10n.adminTheoryCards}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Theory Cards List
          Expanded(
            child: _buildCardsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
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

    if (_theoryCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoTheoryCards,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _theoryCards.length,
        itemBuilder: (context, index) {
          return _buildTheoryCard(_theoryCards[index]);
        },
      ),
    );
  }

  Widget _buildTheoryCard(Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final id = card['id'] as int;
    final titleIt = card['title_it'] ?? '';
    final textIt = card['text_it'] ?? '';
    final imageUrl = card['image_url'];
    final chapter = card['theory_chapters'];
    final chapterName = chapter?['name_it'] ?? '';
    final displayOrder = card['display_order'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(card),
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
                      '#$displayOrder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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
                    onPressed: () => _deleteCard(id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              if (titleIt.isNotEmpty) ...[
                Text(
                  titleIt,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Text Content
              Text(
                textIt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 12),
              
              // Chapter Info
              Row(
                children: [
                  const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      chapterName,
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
    if (_selectedChapterId != null) {
      final chapter = _chapters.firstWhere(
        (c) => c['id'] == _selectedChapterId,
        orElse: () => {},
      );
      if (chapter.isNotEmpty) {
        parts.add(chapter['name_it'] ?? '');
      }
    }
    if (_searchController.text.isNotEmpty) {
      parts.add('"${_searchController.text}"');
    }
    return parts.join(' • ');
  }
}

class _SearchFilterSheet extends StatefulWidget {
  final List<Map<String, dynamic>> chapters;
  final int? selectedChapterId;
  final String initialSearchQuery;
  final Function(int?, String) onApply;

  const _SearchFilterSheet({
    required this.chapters,
    required this.selectedChapterId,
    required this.initialSearchQuery,
    required this.onApply,
  });

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late TextEditingController _searchController;
  int? _selectedChapterId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedChapterId = widget.selectedChapterId;
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
                labelText: l10n.adminSearchTheory,
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

            // Chapter Dropdown
            DropdownButtonFormField<int?>(
              value: _selectedChapterId,
              decoration: InputDecoration(
                labelText: l10n.adminFilterByChapter,
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
                ...widget.chapters.map((chapter) {
                  return DropdownMenuItem<int?>(
                    value: chapter['id'] as int,
                    child: Text(
                      chapter['name_it'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedChapterId = value;
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
                        _selectedChapterId = null;
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
                      widget.onApply(_selectedChapterId, _searchController.text);
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
