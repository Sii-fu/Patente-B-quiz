import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/theory_card.dart';
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
  late AudioPlayer _ttsAudioPlayer;
  late AudioPlayer _audioPlayer;
  
  // Localized audio (replaces device TTS) state
  bool _isTtsSpeaking = false;
  bool _isTtsAudioLoading = false;
  String? _currentTtsAudioUrl;
  
  // Custom audio state
  bool _isCustomAudioPlaying = false;
  bool _isCustomAudioLoading = false;
  Duration _customAudioPosition = Duration.zero;
  Duration _customAudioDuration = Duration.zero;
  
  String _selectedLanguage = 'it';

  @override
  void initState() {
    super.initState();
    _ttsAudioPlayer = AudioPlayer();
    _audioPlayer = AudioPlayer();
    _setupTtsAudioPlayer();
    _setupAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadSelectedLanguageAudio();
    });
  }

  Future<void> _preloadSelectedLanguageAudio({bool showLoading = false}) async {
    final audioUrl = widget.card.getLocalizedAudioUrl(_selectedLanguage);
    if (audioUrl == null || audioUrl.isEmpty) return;
    if (_currentTtsAudioUrl == audioUrl && _ttsAudioPlayer.audioSource != null) return;

    try {
      if (showLoading && mounted) {
        setState(() => _isTtsAudioLoading = true);
      }
      await _ttsAudioPlayer.setUrl(audioUrl);
      _currentTtsAudioUrl = audioUrl;
      if (showLoading && mounted) {
        setState(() => _isTtsAudioLoading = false);
      }
    } catch (e) {
      if (showLoading && mounted) {
        setState(() => _isTtsAudioLoading = false);
      }
      debugPrint('❌ Audio preload error: $e');
    }
  }

  void _setupTtsAudioPlayer() {
    _ttsAudioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isTtsSpeaking = state.playing;
          if (state.playing) _isTtsAudioLoading = false;
        });
      }
    });

    _ttsAudioPlayer.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state == ProcessingState.ready) {
            _isTtsAudioLoading = false;
          } else if (state == ProcessingState.completed) {
            _isTtsSpeaking = false;
          }
        });
      }
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isCustomAudioPlaying = state.playing;
          if (state.playing) _isCustomAudioLoading = false;
        });
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state == ProcessingState.ready) {
            _isCustomAudioLoading = false;
          } else if (state == ProcessingState.completed) {
            _isCustomAudioPlaying = false;
            _customAudioPosition = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted) setState(() => _customAudioDuration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _customAudioPosition = p);
    });
  }

  @override
  void dispose() {
    _ttsAudioPlayer.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleTTS() async {
    HapticFeedback.lightImpact();

    // Stop custom audio if playing
    if (_isCustomAudioPlaying) {
      await _audioPlayer.pause();
      setState(() => _isCustomAudioPlaying = false);
    }

    final audioUrl = widget.card.getLocalizedAudioUrl(_selectedLanguage);
    if (audioUrl == null || audioUrl.isEmpty) return;

    if (_isTtsSpeaking) {
      await _ttsAudioPlayer.pause();
      setState(() => _isTtsSpeaking = false);
    } else {
      try {
        if (_currentTtsAudioUrl != audioUrl || _ttsAudioPlayer.audioSource == null) {
          await _preloadSelectedLanguageAudio(showLoading: true);
        }
        await _ttsAudioPlayer.play();
      } catch (e) {
        debugPrint('❌ Localized audio playback error: $e');
        if (mounted) {
          setState(() => _isTtsAudioLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing audio: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleCustomAudio() async {
    HapticFeedback.lightImpact();

    // Stop TTS if speaking
    if (_isTtsSpeaking) {
      await _ttsAudioPlayer.pause();
      setState(() => _isTtsSpeaking = false);
    }

    final audioUrl = widget.card.audioExplanationUrl;
    if (audioUrl == null || audioUrl.isEmpty) return;

    try {
      if (_isCustomAudioPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.audioSource == null) {
          setState(() => _isCustomAudioLoading = true);
          await _audioPlayer.setUrl(audioUrl);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      setState(() => _isCustomAudioLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
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
            _ttsAudioPlayer.stop();
            _audioPlayer.stop();
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

                  // Audio Controls Section
                  _buildAudioControlsSection(theme),

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

  Widget _buildAudioControlsSection(ThemeData theme) {
    final hasTtsAudio = (widget.card.getLocalizedAudioUrl(_selectedLanguage) ?? '').isNotEmpty;
    final hasCustomAudio = widget.card.audioExplanationUrl != null && 
                           widget.card.audioExplanationUrl!.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Section title
            Icon(Icons.headphones, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Audio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // TTS Button
            _buildAudioButton(
              theme: theme,
              icon: _isTtsSpeaking ? Icons.pause : Icons.play_arrow,
              label: 'TTS',
              sublabel: hasTtsAudio
                  ? (_isTtsSpeaking ? 'Playing...' : 'Language Audio')
                  : 'Not Available',
              isActive: _isTtsSpeaking,
              isLoading: _isTtsAudioLoading,
              onTap: hasTtsAudio ? _toggleTTS : null,
              color: hasTtsAudio ? theme.colorScheme.primary : theme.colorScheme.outline,
              enabled: hasTtsAudio,
            ),
            const SizedBox(width: 12),
            // Custom Audio Button
            _buildAudioButton(
              theme: theme,
              icon: _isCustomAudioPlaying ? Icons.stop : Icons.record_voice_over,
              label: 'Human',
              sublabel: hasCustomAudio 
                  ? (_isCustomAudioPlaying ? 'Playing...' : 'Voice Explanation')
                  : 'Not Available',
              isActive: _isCustomAudioPlaying,
              isLoading: _isCustomAudioLoading,
              onTap: hasCustomAudio ? _toggleCustomAudio : null,
              color: hasCustomAudio ? AppTheme.successGreen : theme.colorScheme.outline,
              enabled: hasCustomAudio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isActive,
    required bool isLoading,
    required VoidCallback? onTap,
    required Color color,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? color : (enabled ? color.withOpacity(0.1) : theme.colorScheme.outline.withOpacity(0.1)),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(isActive ? Colors.white : color),
                ),
              )
            : Icon(
                icon,
                color: isActive ? Colors.white : (enabled ? color : theme.colorScheme.outline),
                size: 28,
              ),
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
        if (_isTtsSpeaking) {
          _ttsAudioPlayer.stop();
          setState(() => _isTtsSpeaking = false);
        }
        _preloadSelectedLanguageAudio();
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
