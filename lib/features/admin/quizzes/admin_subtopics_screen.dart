import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_questions_screen.dart';

/// Admin Subtopics Screen
/// Shows all subtopics for a topic with edit/add functionality
class AdminSubtopicsScreen extends StatefulWidget {
  final int topicId;
  final String topicName;
  final Color categoryColor;

  const AdminSubtopicsScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.categoryColor,
  });

  @override
  State<AdminSubtopicsScreen> createState() => _AdminSubtopicsScreenState();
}

class _AdminSubtopicsScreenState extends State<AdminSubtopicsScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _subtopics = [];
  Map<int, int> _questionCounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubtopics();
  }

  Future<void> _loadSubtopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subtopics = await _adminRepository.getSubtopicsByTopic(widget.topicId);
      
      // Load question counts for each subtopic
      final counts = <int, int>{};
      for (final subtopic in subtopics) {
        final id = subtopic['id'] as int;
        counts[id] = await _adminRepository.getQuestionCountBySubtopic(id);
      }
      
      if (mounted) {
        setState(() {
          _subtopics = subtopics;
          _questionCounts = counts;
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

  void _navigateToQuestions(Map<String, dynamic> subtopic) {
    HapticFeedback.mediumImpact();
    final langCode = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminQuestionsScreen(
          subtopicId: subtopic['id'] as int,
          subtopicName: _getLocalizedName(subtopic, langCode),
          categoryColor: widget.categoryColor,
        ),
      ),
    ).then((_) => _loadSubtopics());
  }

  Future<void> _showEditDialog([Map<String, dynamic>? subtopic]) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final isEditing = subtopic != null;
    
    final nameItController = TextEditingController(text: subtopic?['name_it'] ?? '');
    final nameEnController = TextEditingController(text: subtopic?['name_en'] ?? '');
    final nameBnController = TextEditingController(text: subtopic?['name_bn'] ?? '');
    final imageController = TextEditingController(text: subtopic?['image_url'] ?? '');
    final orderController = TextEditingController(
      text: (subtopic?['display_order'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditSubtopic : l10n.adminAddSubtopic),
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
              
              final success = await _adminRepository.upsertSubtopic(
                id: subtopic?['id'] as int?,
                topicId: widget.topicId,
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
      _loadSubtopics();
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

  Future<void> _deleteSubtopic(Map<String, dynamic> subtopic) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteSubtopic),
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
      final success = await _adminRepository.deleteSubtopic(subtopic['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubtopics();
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
        title: Text(widget.topicName),
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
        label: Text(l10n.adminAddSubtopic),
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
                        onPressed: _loadSubtopics,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _subtopics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.subtitles_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.adminNoSubtopics,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSubtopics,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100,
                        ),
                        itemCount: _subtopics.length,
                        itemBuilder: (context, index) {
                          final subtopic = _subtopics[index];
                          final questionCount = _questionCounts[subtopic['id']] ?? 0;
                          
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
                                child: Center(
                                  child: Text(
                                    questionCount.toString(),
                                    style: TextStyle(
                                      color: widget.categoryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                _getLocalizedName(subtopic, langCode),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '$questionCount ${l10n.totalQuestions.toLowerCase()} • ${l10n.adminDisplayOrder}: ${subtopic['display_order'] ?? 0}',
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
                                    onPressed: () => _showEditDialog(subtopic),
                                    tooltip: l10n.adminEdit,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteSubtopic(subtopic),
                                    tooltip: l10n.adminDelete,
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToQuestions(subtopic),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
