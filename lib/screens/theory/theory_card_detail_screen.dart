import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/theory_card.dart';
import '../../services/tts_helper.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theory_card_quiz_screen.dart';

/// Detail screen showing a single theory card with image, text, and quiz access
class TheoryCardDetailScreen extends StatefulWidget {
  final TheoryCard card;

  const TheoryCardDetailScreen({
    super.key,
    required this.card,
  });

  @override
  State<TheoryCardDetailScreen> createState() => _TheoryCardDetailScreenState();
}

class _TheoryCardDetailScreenState extends State<TheoryCardDetailScreen> {
  late TtsHelper _ttsHelper;
  bool _isSpeaking = false;
  String _selectedLanguage = 'it';

  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper();
    _ttsHelper.init();
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    super.dispose();
  }

  Future<void> _toggleTTS() async {
    HapticFeedback.lightImpact();

    if (_isSpeaking) {
      _ttsHelper.stop();
      setState(() => _isSpeaking = false);
    } else {
      final text = widget.card.getLocalizedText(_selectedLanguage);
      final title = widget.card.getLocalizedTitle(_selectedLanguage);

      if (text.isEmpty) {
        return;
      }

      final fullText = title != null && title.isNotEmpty ? '$title. $text' : text;

      // Check if language is available
      final isAvailable = await _ttsHelper.isLanguageAvailable(_selectedLanguage);
      if (!isAvailable && _selectedLanguage == 'it') {
        if (mounted) {
          _showLanguageNotAvailableDialog(_selectedLanguage);
        }
        return;
      }

      setState(() => _isSpeaking = true);
      _speakText(fullText, _selectedLanguage);
    }
  }

  void _speakText(String text, String languageCode) async {
    try {
      await _ttsHelper.speak(text, languageCode, awaitCompletion: true);
    } catch (e) {
      print('❌ TTS error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  void _showLanguageNotAvailableDialog(String languageCode) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageName = languageCode == 'it' ? 'Italiano' : 
                         languageCode == 'en' ? 'English' : 'বাংলা';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.volume_up, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(l10n.ttsInstallTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.ttsLanguageNotInstalled} $languageName.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ttsInstallPrompt,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ttsLater),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _ttsHelper.launchTtsInstallation();
            },
            icon: const Icon(Icons.download),
            label: Text(l10n.ttsInstall),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = widget.card.getLocalizedTitle(_selectedLanguage);
    final text = widget.card.getLocalizedText(_selectedLanguage);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            _ttsHelper.stop();
            Navigator.pop(context);
          },
        ),
        title: Text(
          title ?? l10n.theoryCardDetailTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          // TTS Button
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.stop_circle : Icons.volume_up,
              size: 28,
            ),
            onPressed: _toggleTTS,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image (if available)
                  if (widget.card.imageUrl != null)
                    _buildCardImage(widget.card.imageUrl!),

                  const SizedBox(height: 20),

                  // Title
                  if (title != null && title.isNotEmpty)
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                  if (title != null && title.isNotEmpty)
                    const SizedBox(height: 16),

                  // Language Toggle
                  _buildLanguageToggle(),

                  const SizedBox(height: 20),

                  // Text Content
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.6,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chapter Info
                  _buildChapterInfo(),
                ],
              ),
            ),
          ),

          // Bottom Action Button - View Quizzes
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildCardImage(String imageUrl) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFullScreenImage(imageUrl);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            height: 200,
            color: theme.colorScheme.surfaceContainerLowest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: theme.colorScheme.surfaceContainerLowest,
            child: Icon(
              Icons.image_not_supported,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildLanguageButton('IT', 'it'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildLanguageButton('EN', 'en'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildLanguageButton('BN', 'bn'),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(String label, String languageCode) {
    final isActive = _selectedLanguage == languageCode;
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLanguage = languageCode);
        // Stop TTS when switching languages
        if (_isSpeaking) {
          _ttsHelper.stop();
          setState(() => _isSpeaking = false);
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surface,
        foregroundColor: isActive 
            ? theme.colorScheme.onPrimary 
            : theme.colorScheme.onSurface,
        side: BorderSide(
          color: isActive 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildChapterInfo() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.book,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '${l10n.theoryCardDetailChapter} ${widget.card.chapterId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Only show quiz button if card has subtopic_id
    if (widget.card.subtopicId == null) {
      print(widget.card);
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TheoryCardQuizScreen(
                  theoryCard: widget.card,
                ),
              ),
            );
          },
          icon: const Icon(Icons.quiz),
          label: Text(l10n.theoryCardDetailViewQuizzes),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
