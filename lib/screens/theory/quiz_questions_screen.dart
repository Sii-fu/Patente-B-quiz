import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:just_audio/just_audio.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../../services/tts_helper.dart';
import '../../features/admin/services/admin_repository.dart';
import '../../models/profile.dart';
import 'edit_question_screen.dart';

class QuizQuestionsScreen extends StatefulWidget {
  final int subtopicId;
  final String cardTitle;

  const QuizQuestionsScreen({
    super.key,
    required this.subtopicId,
    required this.cardTitle,
  });

  @override
  State<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen> {
  final _supabase = Supabase.instance.client;
  final AdminRepository _adminRepo = AdminRepository();
  final TtsHelper _ttsHelper = TtsHelper();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  bool _isLoading = true;
  String? _error;
  bool _isSearching = false;
  bool _isAdmin = false;

  final Set<int> _visibleExplanations = {};
  final Map<int, String> _questionLanguages = {};

  // Audio player for question TTS from URL
  AudioPlayer? _ttsAudioPlayer;
  bool _isTtsPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
    _checkAdminStatus();
    _loadQuestions();
  }

  Future<void> _checkAdminStatus() async {
    final profile = await _adminRepo.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _isAdmin = profile?.isAdmin ?? false;
      });
    }
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    _ttsAudioPlayer?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabase
          .from('questions')
          .select('id, text_it, text_en, text_bn, image_url, is_true, explanation_it, explanation_en, explanation_bn, difficulty_level, explanation_audio_url, audio_it_url, audio_en_url, audio_bn_url')
          .eq('subtopic_id', widget.subtopicId)
          .order('id', ascending: true);

      // Debug: Log audio URLs
      for (var q in response) {
        debugPrint('🎙️ Q${q['id']}: audioUrl = ${q['explanation_audio_url']}');
      }

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        _filteredQuestions = _questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterQuestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = _questions;
      } else {
        _filteredQuestions = _questions.where((q) {
          final textIt = q['text_it']?.toString().toLowerCase() ?? '';
          final textEn = q['text_en']?.toString().toLowerCase() ?? '';
          final textBn = q['text_bn']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return textIt.contains(searchLower) ||
                 textEn.contains(searchLower) ||
                 textBn.contains(searchLower);
        }).toList();
      }
    });
  }

  String _getLocalizedText(Map<String, dynamic> question, String languageCode, String field) {
    final fieldName = '${field}_$languageCode';
    final fallbackField = '${field}_it';
    return question[fieldName]?.toString() ?? question[fallbackField]?.toString() ?? '';
  }

  String _getQuestionLanguage(int questionId, String defaultLanguage) {
    return _questionLanguages[questionId] ?? defaultLanguage;
  }

  void _setQuestionLanguage(int questionId, String language) {
    setState(() {
      _questionLanguages[questionId] = language;
    });
  }

  void _toggleExplanation(int questionId) {
    setState(() {
      if (_visibleExplanations.contains(questionId)) {
        _visibleExplanations.remove(questionId);
      } else {
        _visibleExplanations.add(questionId);
      }
    });
  }

  Future<void> _speakText(String text, String languageCode, {String? audioUrl}) async {
    // Toggle off if already playing
    if (_isTtsPlaying) {
      await _ttsAudioPlayer?.stop();
      setState(() => _isTtsPlaying = false);
      return;
    }
    
    // Try to play from URL first, fall back to device TTS
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _playTtsFromUrl(audioUrl);
    } else {
      await _ttsHelper.speak(text, languageCode);
    }
  }

  Future<void> _playTtsFromUrl(String audioUrl) async {
    // Initialize TTS audio player if needed
    if (_ttsAudioPlayer == null) {
      _ttsAudioPlayer = AudioPlayer();
      
      _ttsAudioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isTtsPlaying = state.playing);
        }
      });
      
      _ttsAudioPlayer!.processingStateStream.listen((state) {
        if (mounted && state == ProcessingState.completed) {
          setState(() => _isTtsPlaying = false);
        }
      });
    }
    
    try {
      setState(() => _isTtsPlaying = true);
      await _ttsAudioPlayer!.setUrl(audioUrl);
      await _ttsAudioPlayer!.play();
    } catch (e) {
      debugPrint('❌ TTS audio playback error: $e');
      setState(() => _isTtsPlaying = false);
    }
  }

  void _showImageFullscreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: l10n.searchQuestions,
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: _filterQuestions,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_filteredQuestions.length} ${l10n.quizSubmitQuestions}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filteredQuestions = _questions;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredQuestions = _questions;
                }
              });
            },
          ),
        ],
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
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? l10n.noResultsForSearch
                  : l10n.noQuestionsAvailable,
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
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = _filteredQuestions[index];
        return _buildQuestionCard(question, theme, currentLanguage, index + 1);
      },
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
    ThemeData theme,
    String currentLanguage,
    int questionNumber,
  ) {
    final questionId = question['id'] as int;
    final questionLang = _getQuestionLanguage(questionId, currentLanguage);
    final questionText = _getLocalizedText(question, questionLang, 'text');
    final explanation = _getLocalizedText(question, questionLang, 'explanation');
    final isTrue = question['is_true'] as bool;
    final imageUrl = question['image_url'] as String?;
    final showExplanation = _visibleExplanations.contains(questionId);

    // Define answer colors
    final correctColor = AppTheme.successGreen;
    final incorrectColor = AppTheme.errorRed;
    final audioUrl = question['explanation_audio_url'] as String?;
    
    // Get question audio URL based on language
    String? questionAudioUrl;
    switch (questionLang) {
      case 'en':
        questionAudioUrl = question['audio_en_url'] as String? ?? question['audio_it_url'] as String?;
        break;
      case 'bn':
        questionAudioUrl = question['audio_bn_url'] as String? ?? question['audio_it_url'] as String?;
        break;
      default:
        questionAudioUrl = question['audio_it_url'] as String?;
    }

    return GestureDetector(
      onTap: _isAdmin ? () => _navigateToEdit(question) : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$questionNumber',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Language switcher
                  _buildLanguageSwitcher(questionId, questionLang, theme),
                  const SizedBox(width: 8),
                  // TTS button
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    color: theme.colorScheme.primary,
                    onPressed: () => _speakText(questionText, questionLang, audioUrl: questionAudioUrl),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Audio explanation button (if available)
                  if (audioUrl != null && audioUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.headphones, size: 20),
                      color: AppTheme.successGreen,
                      onPressed: () => _playExplanationAudio(audioUrl),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Play audio explanation',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Question text
              Text(
                questionText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),

              // Image if available
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showImageFullscreen(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Answer badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTrue ? correctColor : incorrectColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrue ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isTrue ? 'VERO' : 'FALSO',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Explanation toggle
                if (explanation.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _toggleExplanation(questionId),
                    icon: Icon(
                      showExplanation ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      showExplanation ? 'Hide Explanation' : 'Show Explanation',
                    ),
                  ),
              ],
            ),

            // Explanation
            if (showExplanation && explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 18),
                      color: theme.colorScheme.primary,
                      onPressed: () => _speakText(explanation, questionLang),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      )
    );
  }

  Widget _buildLanguageSwitcher(int questionId, String currentLang, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.language,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      padding: EdgeInsets.zero,
      onSelected: (lang) => _setQuestionLanguage(questionId, lang),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'it',
          child: Row(
            children: [
              if (currentLang == 'it')
                Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
              if (currentLang == 'it') const SizedBox(width: 8),
              const Text('🇮🇹 Italiano'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              if (currentLang == 'en')
                Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
              if (currentLang == 'en') const SizedBox(width: 8),
              const Text('🇬🇧 English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'bn',
          child: Row(
            children: [
              if (currentLang == 'bn')
                Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
              if (currentLang == 'bn') const SizedBox(width: 8),
              const Text('🇧🇩 বাংলা'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToEdit(Map<String, dynamic> question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(
          question: question,
          subtopicId: widget.subtopicId,
        ),
      ),
    );

    // Reload questions if edit was successful
    if (result == true) {
      _loadQuestions();
    }
  }

  /// Play audio explanation using just_audio
  Future<void> _playExplanationAudio(String audioUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playing audio explanation...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Show audio player in a bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (context) => QuestionAudioPlayer(audioUrl: audioUrl),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Simple audio player widget for explanation audio in bottom sheet
class QuestionAudioPlayer extends StatefulWidget {
  final String audioUrl;

  const QuestionAudioPlayer({
    super.key,
    required this.audioUrl,
  });

  @override
  State<QuestionAudioPlayer> createState() => _QuestionAudioPlayerState();
}

class _QuestionAudioPlayerState extends State<QuestionAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isUrlLoaded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.playing) _isLoading = false;
        });
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state == ProcessingState.ready ||
              state == ProcessingState.completed) {
            _isLoading = false;
            _isUrlLoaded = true;
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        if (!_isUrlLoaded) {
          setState(() => _isLoading = true);
          await _audioPlayer.setUrl(widget.audioUrl);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Audio Explanation',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_bottom
                        : (_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration.inMilliseconds
                  : 0,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                _formatDuration(_duration),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
