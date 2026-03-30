import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_theory_cards_screen.dart';

/// Admin Theory Chapters Screen
/// Shows all theory chapters with edit/add functionality
class AdminTheoryChaptersScreen extends StatefulWidget {
  const AdminTheoryChaptersScreen({super.key});

  @override
  State<AdminTheoryChaptersScreen> createState() => _AdminTheoryChaptersScreenState();
}

class _AdminTheoryChaptersScreenState extends State<AdminTheoryChaptersScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _chapters = [];
  Map<int, int> _cardCounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chapters = await _adminRepository.getTheoryChapters();
      
      // Sort chapters ascending by display_order
      chapters.sort((a, b) {
        final aOrder = (a['display_order'] as int?) ?? 0;
        final bOrder = (b['display_order'] as int?) ?? 0;
        return aOrder.compareTo(bOrder);
      });

      // Load card counts for each chapter
      final counts = <int, int>{};
      for (final chapter in chapters) {
        final id = chapter['id'] as int;
        counts[id] = await _adminRepository.getTheoryCardCountByChapter(id);
      }
      
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _cardCounts = counts;
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

  String _getLocalizedName(Map<String, dynamic> item, String langCode) {
    switch (langCode) {
      case 'en':
        return item['name_en'] ?? item['name_it'] ?? '';
      case 'bn':
        return item['name_bn'] ?? item['name_it'] ?? '';
      default:
        return item['name_it'] ?? '';
    }
  }

  void _navigateToCards(Map<String, dynamic> chapter) {
    HapticFeedback.mediumImpact();
    final langCode = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTheoryCardsScreen(
          chapterId: chapter['id'] as int,
          chapterName: _getLocalizedName(chapter, langCode),
        ),
      ),
    ).then((_) => _loadChapters());
  }

  Future<void> _showEditDialog([Map<String, dynamic>? chapter]) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final isEditing = chapter != null;
    
    final nameItController = TextEditingController(text: chapter?['name_it'] ?? '');
    final nameEnController = TextEditingController(text: chapter?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: chapter?['name_bn'] ?? '');
    final imageController = TextEditingController(text: chapter?['image_url'] ?? '');
    final orderController = TextEditingController(
      text: (chapter?['display_order'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditChapter : l10n.adminAddChapter),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameItController,
                decoration: InputDecoration(
                  labelText: '${l10n.adminNameIt} *',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameEnController,
                decoration: InputDecoration(
                  labelText: l10n.adminNameEn,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameBnController,
                decoration: InputDecoration(
                  labelText: l10n.adminNameBn,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: InputDecoration(
                  labelText: l10n.adminImageUrl,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.adminDisplayOrder,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (nameItController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.adminFieldRequired)),
                );
                return;
              }
              
              final success = await _adminRepository.upsertTheoryChapter(
                id: chapter?['id'] as int?,
                nameIt: nameItController.text,
                nameEn: nameEnController.text.isEmpty ? null : nameEnController.text,
                nameBn: nameBnController.text.isEmpty ? null : nameBnController.text,
                imageUrl: imageController.text.isEmpty ? null : imageController.text,
                displayOrder: int.tryParse(orderController.text) ?? 0,
              );
              
              if (context.mounted) {
                Navigator.pop(context, success);
              }
            },
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteChapter(Map<String, dynamic> chapter) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteChapter),
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
      final success = await _adminRepository.deleteTheoryChapter(chapter['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        _loadChapters();
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
        title: Text(l10n.adminTheoryChapters),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddChapter),
      ),
      body: _isLoading
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
                        onPressed: _loadChapters,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _chapters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.adminNoChapters,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChapters,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100,
                        ),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          final cardCount = _cardCounts[chapter['id']] ?? 0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                _getLocalizedName(chapter, langCode),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '$cardCount ${l10n.adminTheoryCards.toLowerCase()} • ${l10n.adminDisplayOrder}: ${chapter['display_order'] ?? 0}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditDialog(chapter),
                                    tooltip: l10n.adminEdit,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteChapter(chapter),
                                    tooltip: l10n.adminDelete,
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToCards(chapter),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
