import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_subtopics_screen.dart';

/// Admin Topics Screen
/// Shows all topics for a category with edit/add functionality
class AdminTopicsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final Color categoryColor;

  const AdminTopicsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<AdminTopicsScreen> createState() => _AdminTopicsScreenState();
}

class _AdminTopicsScreenState extends State<AdminTopicsScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _topics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topics = await _adminRepository.getTopicsByCategory(widget.categoryId);
      if (mounted) {
        setState(() {
          _topics = topics;
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

  void _navigateToSubtopics(Map<String, dynamic> topic) {
    HapticFeedback.mediumImpact();
    final langCode = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSubtopicsScreen(
          topicId: topic['id'] as int,
          topicName: _getLocalizedName(topic, langCode),
          categoryColor: widget.categoryColor,
        ),
      ),
    ).then((_) => _loadTopics());
  }

  Future<void> _showEditDialog([Map<String, dynamic>? topic]) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final isEditing = topic != null;
    
    final nameItController = TextEditingController(text: topic?['name_it'] ?? '');
    final nameEnController = TextEditingController(text: topic?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: topic?['name_bn'] ?? '');
    final imageController = TextEditingController(text: topic?['image_url'] ?? '');
    final orderController = TextEditingController(
      text: (topic?['display_order'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditTopic : l10n.adminAddTopic),
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
              
              final success = await _adminRepository.upsertTopic(
                id: topic?['id'] as int?,
                categoryId: widget.categoryId,
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
      _loadTopics();
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

  Future<void> _deleteTopic(Map<String, dynamic> topic) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteTopic),
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
      final success = await _adminRepository.deleteTopic(topic['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        _loadTopics();
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
        title: Text(widget.categoryName),
        backgroundColor: widget.categoryColor.withOpacity(0.1),
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
        label: Text(l10n.adminAddTopic),
        backgroundColor: widget.categoryColor,
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
                        onPressed: _loadTopics,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _topics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.topic_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.adminNoTopics,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTopics,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100,
                        ),
                        itemCount: _topics.length,
                        itemBuilder: (context, index) {
                          final topic = _topics[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: widget.categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.topic,
                                  color: widget.categoryColor,
                                ),
                              ),
                              title: Text(
                                _getLocalizedName(topic, langCode),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'ID: ${topic['id']} • ${l10n.adminDisplayOrder}: ${topic['display_order'] ?? 0}',
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
                                    onPressed: () => _showEditDialog(topic),
                                    tooltip: l10n.adminEdit,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteTopic(topic),
                                    tooltip: l10n.adminDelete,
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToSubtopics(topic),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
