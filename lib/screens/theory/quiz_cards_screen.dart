import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'quiz_questions_screen.dart';
import '../../features/admin/services/admin_repository.dart';
import '../../models/profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class QuizCardsScreen extends StatefulWidget {
  final int chapterId;
  final String chapterName;

  const QuizCardsScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  State<QuizCardsScreen> createState() => _QuizCardsScreenState();
}

class _QuizCardsScreenState extends State<QuizCardsScreen> {
  final _supabase = Supabase.instance.client;
  final AdminRepository _adminRepo = AdminRepository();
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadCards();
  }

  Future<void> _checkAdminStatus() async {
    final profile = await _adminRepo.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _isAdmin = profile?.isAdmin ?? false;
      });
    }
  }

  Future<void> _loadCards() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabase
          .from('theory_cards')
          .select('id, title_it, title_en, title_bn, text_it, text_en, text_bn, image_url, subtopic_id, display_order')
          .eq('chapter_id', widget.chapterId)
          .order('id', ascending: true);

      setState(() {
        _cards = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getLocalizedTitle(Map<String, dynamic> card, String languageCode) {
    switch (languageCode) {
      case 'en':
        return card['title_en'] ?? card['title_it'] ?? 'Card ${card['id']}';
      case 'bn':
        return card['title_bn'] ?? card['title_it'] ?? 'Card ${card['id']}';
      default:
        return card['title_it'] ?? 'Card ${card['id']}';
    }
  }

  String _getLocalizedText(Map<String, dynamic> card, String languageCode) {
    switch (languageCode) {
      case 'en':
        return card['text_en'] ?? card['text_it'] ?? '';
      case 'bn':
        return card['text_bn'] ?? card['text_it'] ?? '';
      default:
        return card['text_it'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapterName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              l10n.adminTheoryCards,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(theme, l10n, currentLanguage),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n, String currentLanguage) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.theoryCardQuizErrorLoading,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCards,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoTheoryCards,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildCardItem(card, theme, currentLanguage);
      },
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card, ThemeData theme, String currentLanguage) {
    final l10n = AppLocalizations.of(context)!;
    final cardTitle = _getLocalizedTitle(card, currentLanguage);
    final cardText = _getLocalizedText(card, currentLanguage);
    final subtopicId = card['subtopic_id'] as int?;
    final imageUrl = card['image_url'] as String?;

    // Show preview of text (first 100 characters)
    final previewText = cardText.length > 100 
        ? '${cardText.substring(0, 100)}...' 
        : cardText;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (subtopicId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.theoryCardQuizEmpty,
                ),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            return;
          }

          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizQuestionsScreen(
                subtopicId: subtopicId,
                cardTitle: cardTitle,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.description,
                            size: 28,
                            color: theme.colorScheme.primary,
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.description,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cardTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_isAdmin)
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      color: theme.colorScheme.primary,
                      onPressed: () => _showEditCardDialog(card, theme),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (_isAdmin) const SizedBox(width: 8),
                  if (subtopicId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Quiz',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (previewText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  previewText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCardDialog(Map<String, dynamic> card, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => _EditTheoryCardDialog(
        card: card,
        chapterId: widget.chapterId,
        adminRepo: _adminRepo,
        onSaved: _loadCards,
      ),
    );
  }
}

// Stateful dialog for editing theory cards with image picker
class _EditTheoryCardDialog extends StatefulWidget {
  final Map<String, dynamic> card;
  final int chapterId;
  final AdminRepository adminRepo;
  final VoidCallback onSaved;

  const _EditTheoryCardDialog({
    required this.card,
    required this.chapterId,
    required this.adminRepo,
    required this.onSaved,
  });

  @override
  State<_EditTheoryCardDialog> createState() => _EditTheoryCardDialogState();
}

class _EditTheoryCardDialogState extends State<_EditTheoryCardDialog> {
  late TextEditingController titleItController;
  late TextEditingController titleEnController;
  late TextEditingController titleBnController;
  late TextEditingController textItController;
  late TextEditingController textEnController;
  late TextEditingController textBnController;
  late TextEditingController displayOrderController;
  
  String? imageUrl;
  File? selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleItController = TextEditingController(text: widget.card['title_it']);
    titleEnController = TextEditingController(text: widget.card['title_en']);
    titleBnController = TextEditingController(text: widget.card['title_bn']);
    textItController = TextEditingController(text: widget.card['text_it']);
    textEnController = TextEditingController(text: widget.card['text_en']);
    textBnController = TextEditingController(text: widget.card['text_bn']);
    displayOrderController = TextEditingController(
      text: (widget.card['display_order'] ?? 1).toString(),
    );
    imageUrl = widget.card['image_url'];
  }

  @override
  void dispose() {
    titleItController.dispose();
    titleEnController.dispose();
    titleBnController.dispose();
    textItController.dispose();
    textEnController.dispose();
    textBnController.dispose();
    displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveCard() async {
    if (textItController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Italian content is required')),
      );
      return;
    }

    setState(() => isSaving = true);

    String? finalImageUrl = imageUrl;

    // Upload new image if selected
    if (selectedImageFile != null) {
      final bytes = await selectedImageFile!.readAsBytes();
      final fileName = 'theory_cards/${DateTime.now().millisecondsSinceEpoch}.jpg';
      finalImageUrl = await widget.adminRepo.uploadImage('quiz_images', fileName, bytes);
      
      if (finalImageUrl == null) {
        if (mounted) {
          setState(() => isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
    }

    final success = await widget.adminRepo.upsertTheoryCard(
      id: widget.card['id'] as int,
      chapterId: widget.chapterId,
      titleIt: titleItController.text.trim().isEmpty ? null : titleItController.text.trim(),
      titleEn: titleEnController.text.trim().isEmpty ? null : titleEnController.text.trim(),
      titleBn: titleBnController.text.trim().isEmpty ? null : titleBnController.text.trim(),
      textIt: textItController.text.trim(),
      textEn: textEnController.text.trim().isEmpty ? null : textEnController.text.trim(),
      textBn: textBnController.text.trim().isEmpty ? null : textBnController.text.trim(),
      imageUrl: finalImageUrl,
      displayOrder: int.tryParse(displayOrderController.text) ?? 1,
    );

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theory card updated successfully')),
        );
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update theory card')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Theory Card',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Text('Image', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: selectedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : imageUrl != null && imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stack) {
                                        return _buildImagePlaceholder();
                                      },
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change image',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text('Title (Italian)', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: titleItController,
                      decoration: const InputDecoration(hintText: 'Title in Italian'),
                    ),
                    const SizedBox(height: 12),
                    Text('Title (English)', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: titleEnController,
                      decoration: const InputDecoration(hintText: 'Title in English'),
                    ),
                    const SizedBox(height: 12),
                    Text('Title (Bangla)', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: titleBnController,
                      decoration: const InputDecoration(hintText: 'Title in Bangla'),
                    ),
                    const SizedBox(height: 16),
                    Text('Content (Italian)*', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: textItController,
                      decoration: const InputDecoration(hintText: 'Required'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Text('Content (English)', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: textEnController,
                      decoration: const InputDecoration(hintText: 'Optional'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Text('Content (Bangla)', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: textBnController,
                      decoration: const InputDecoration(hintText: 'Optional'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Text('Display Order', style: theme.textTheme.labelMedium),
                    TextField(
                      controller: displayOrderController,
                      decoration: const InputDecoration(hintText: '1'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveCard,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
