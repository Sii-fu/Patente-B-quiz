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
import 'edit_theory_card_screen.dart';
import '../../services/admin_selection_state.dart';

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
          .select(
            'id, title_it, title_en, title_bn, text_it, text_en, text_bn, image_url, subtopic_id, display_order',
          )
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

  Widget _buildBody(
    ThemeData theme,
    AppLocalizations l10n,
    String currentLanguage,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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

  Widget _buildCardItem(
    Map<String, dynamic> card,
    ThemeData theme,
    String currentLanguage,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cardTitle =
        '${card['id'] % 100}. ${_getLocalizedTitle(card, currentLanguage)}';
    final cardText = _getLocalizedText(card, currentLanguage);
    final subtopicId = card['subtopic_id'] as int?;
    final imageUrl = card['image_url'] as String?;

    // Show preview of text (first 100 characters)
    // final previewText = cardText.length > 100
    //     ? '${cardText.substring(0, 100)}...'
    //     : cardText;

    final previewText = cardText;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (subtopicId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.theoryCardQuizEmpty),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            return;
          }

          HapticFeedback.lightImpact();
          AdminSelectionState.rememberSubtopic(widget.chapterId, subtopicId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizQuestionsScreen(
                subtopicId: subtopicId,
                cardTitle: cardTitle,
                chapterId: widget.chapterId,
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
                        fontWeight: FontWeight.w700,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCardDialog(Map<String, dynamic> card, ThemeData theme) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTheoryCardScreen(card: card, chapterId: widget.chapterId),
      ),
    );

    // Reload cards if changes were made
    if (result == true) {
      _loadCards();
    }
  }
}
