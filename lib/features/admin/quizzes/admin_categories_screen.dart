import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_topics_screen.dart';
import 'admin_questions_screen.dart';
import 'admin_subtopics_screen.dart';
import '../../../screens/theory/quiz_cards_screen.dart';

/// Admin Categories Screen
/// Shows all quiz categories with edit/add functionality
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _adminRepository.getTheoryChapters();
      if (mounted) {
        setState(() {
          _categories = categories;
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

  Color _parseColor(String? colorHex) {
    final theme = Theme.of(context);
    if (colorHex == null || colorHex.isEmpty) {
      return theme.colorScheme.primary;
    }
    try {
      final hexString = colorHex.replaceAll('0x', '').replaceAll('#', '');
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return theme.colorScheme.primary;
    }
  }

  void _navigateToquizzes(Map<String, dynamic> category) {
    HapticFeedback.mediumImpact();
    final chapterId = category['id'] as int;
    final langCode = Localizations.localeOf(context).languageCode;
    
    // Navigate to theory cards screen for this chapter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCardsScreen(
          chapterId: chapterId,
          chapterName: _getLocalizedName(category, langCode),
        ),
      ),
    ).then((_) => _loadCategories());
  }

  void _navigateToTopics(Map<String, dynamic> category) {
    HapticFeedback.mediumImpact();
    final langCode = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTopicsScreen(
          categoryId: category['id'] as int,
          categoryName: _getLocalizedName(category, langCode),
          categoryColor: _parseColor(category['color_hex'] as String?),
        ),
      ),
    ).then((_) => _loadCategories());
  }

  Future<void> _showEditDialog([Map<String, dynamic>? category]) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final isEditing = category != null;
    
    final nameItController = TextEditingController(text: category?['name_it'] ?? '');
    final nameEnController = TextEditingController(text: category?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: category?['name_bn'] ?? '');
    final colorController = TextEditingController(text: category?['color_hex'] ?? '');
    final orderController = TextEditingController(
      text: (category?['display_order'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditCategory : l10n.adminAddCategory),
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
                controller: colorController,
                decoration: InputDecoration(
                  labelText: l10n.adminColorHex,
                  hintText: 'e.g., 0xFF3498DB',
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
              
              final success = await _adminRepository.upsertCategory(
                id: category?['id'] as int?,
                nameIt: nameItController.text,
                nameEn: nameEnController.text.isEmpty ? null : nameEnController.text,
                nameBn: nameBnController.text.isEmpty ? null : nameBnController.text,
                colorHex: colorController.text.isEmpty ? null : colorController.text,
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
      _loadCategories();
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

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteCategory),
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
      final success = await _adminRepository.deleteCategory(category['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories();
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
        title: Text(l10n.adminQuizCategories),
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
        label: Text(l10n.adminAddCategory),
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
                        onPressed: _loadCategories,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.adminNoCategories,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final color = _parseColor(category['color_hex'] as String?);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.category,
                                color: color,
                              ),
                              ),
                              title: Text(
                              _getLocalizedName(category, langCode),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                              'ID: ${category['id']} • ${l10n.adminDisplayOrder}: ${category['display_order'] ?? 0}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              ),
                              trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  debugPrint('Clicked: Edit category ${category['id']} - ${_getLocalizedName(category, langCode)}');
                                  _showEditDialog(category);
                                },
                                tooltip: l10n.adminEdit,
                                ),
                                IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {
                                  debugPrint('Clicked: Delete category ${category['id']} - ${_getLocalizedName(category, langCode)}');
                                  _deleteCategory(category);
                                },
                                tooltip: l10n.adminDelete,
                                ),
                              ],
                              ),
                              onTap: () {
                              debugPrint('Clicked: Category item ${category['id']} - ${_getLocalizedName(category, langCode)}');
                              _navigateToquizzes(category);
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
