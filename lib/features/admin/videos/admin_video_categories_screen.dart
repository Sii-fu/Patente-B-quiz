import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_videos_screen.dart';

/// Admin Video Categories Screen
/// Lists all video categories with edit/add/delete functionality
class AdminVideoCategoriesScreen extends StatefulWidget {
  const AdminVideoCategoriesScreen({super.key});

  @override
  State<AdminVideoCategoriesScreen> createState() => _AdminVideoCategoriesScreenState();
}

class _AdminVideoCategoriesScreenState extends State<AdminVideoCategoriesScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _categories = [];
  Map<int, int> _videoCounts = {};
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
      final categories = await _adminRepository.getVideoCategories();
      
      // Load video counts for each category
      final counts = <int, int>{};
      for (final cat in categories) {
        final count = await _adminRepository.getVideoCountByCategory(cat['id'] as int);
        counts[cat['id'] as int] = count;
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _videoCounts = counts;
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

  Future<void> _showCategoryDialog([Map<String, dynamic>? category]) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = category != null;
    
    final nameItController = TextEditingController(text: category?['name_it'] ?? '');
    final nameEnController = TextEditingController(text: category?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: category?['name_bn'] ?? '');
    final displayOrderController = TextEditingController(
      text: (category?['display_order'] ?? 0).toString()
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditVideoCategory : l10n.adminAddVideoCategory),
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
              const SizedBox(height: 16),
              TextField(
                controller: nameEnController,
                decoration: InputDecoration(
                  labelText: l10n.adminNameEn,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameBnController,
                decoration: InputDecoration(
                  labelText: l10n.adminNameBn,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displayOrderController,
                decoration: InputDecoration(
                  labelText: l10n.adminDisplayOrder,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameItController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.adminNameRequired),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              final success = await _adminRepository.upsertVideoCategory(
                id: category?['id'],
                nameIt: nameItController.text.trim(),
                nameEn: nameEnController.text.trim().isEmpty ? null : nameEnController.text.trim(),
                nameBn: nameBnController.text.trim().isEmpty ? null : nameBnController.text.trim(),
                displayOrder: int.tryParse(displayOrderController.text) ?? 0,
              );

              if (success && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.settingsSave),
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
    final videoCount = _videoCounts[category['id']] ?? 0;
    
    String message = l10n.adminDeleteConfirm;
    if (videoCount > 0) {
      message = l10n.adminDeleteCategoryWarning(videoCount);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteVideoCategory),
        content: Text(message),
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
      final success = await _adminRepository.deleteVideoCategory(category['id'] as int);
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

  void _navigateToVideos(Map<String, dynamic> category, String langCode) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminVideosScreen(
          categoryId: category['id'] as int,
          categoryName: _getLocalizedName(category, langCode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminVideoCategories),
        backgroundColor: Colors.purple.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddVideoCategory),
        backgroundColor: Colors.purple,
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
                          const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.adminNoVideoCategories,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showCategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.adminAddVideoCategory),
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
                          final name = _getLocalizedName(category, langCode);
                          final videoCount = _videoCounts[category['id']] ?? 0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _navigateToVideos(category, langCode),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Category Icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.video_library,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Category Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$videoCount ${l10n.adminVideos}',
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Actions
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showCategoryDialog(category),
                                      tooltip: l10n.adminEdit,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteCategory(category),
                                      tooltip: l10n.adminDelete,
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
