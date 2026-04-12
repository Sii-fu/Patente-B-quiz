import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/theory_card.dart';
import '../../models/question.dart';
import '../../models/subtopic.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import '../../services/tts_helper.dart';
import '../dashboard/custom_quiz_screen.dart';

/// Screen showing all questions related to a theory card's subtopic (study/reference mode)
class TheoryCardQuizScreen extends StatefulWidget {
  final TheoryCard theoryCard;

  const TheoryCardQuizScreen({
    super.key,
    required this.theoryCard,
  });

  @override
  State<TheoryCardQuizScreen> createState() => _TheoryCardQuizScreenState();
}

class _TheoryCardQuizScreenState extends State<TheoryCardQuizScreen> {
  final _supabase = Supabase.instance.client;
  final TtsHelper _ttsHelper = TtsHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];
  bool _isLoading = true;
  String? _error;
  bool _isSearching = false;
  
  // Track which questions have visible explanations
  final Set<int> _visibleExplanations = {};
  
  // Track language for each question individually
  final Map<int, String> _questionLanguages = {};
  
  // Audio player for custom audio
  final Map<int, AudioPlayer> _audioPlayers = {};
  final Map<int, bool> _isAudioPlaying = {};
  final Map<int, bool> _isAudioLoading = {};
  
  // TTS state tracking
  int? _currentTtsQuestionId;
  bool _isTtsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
    _loadQuestions();
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    _searchController.dispose();
    // Dispose all audio players
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      // Check if theory card has subtopic_id
      if (widget.theoryCard.subtopicId == null) {
        setState(() {
          _questions = [];
          _filteredQuestions = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch questions by subtopic_id directly from Supabase
      final questionsResponse = await _supabase
          .from('questions')
          .select('*, subtopics(*)')
          .eq('subtopic_id', widget.theoryCard.subtopicId!)
          .order('id');

      final questions = (questionsResponse as List).map((q) {
        final subtopicData = q['subtopics'];
        return Question(
          id: q['id'] as int,
          subtopicId: q['subtopic_id'] as int?,
          textIt: q['text_it'] as String,
          textEn: q['text_en'] as String?,
          textBn: q['text_bn'] as String?,
          imageUrl: q['image_url'] as String?,
          isTrue: q['is_true'] as bool,
          explanationIt: q['explanation_it'] as String?,
          explanationEn: q['explanation_en'] as String?,
          explanationBn: q['explanation_bn'] as String?,
          explanationAudioUrl: q['explanation_audio_url'] as String?,
          difficultyLevel: q['difficulty_level'] as int? ?? 1,
          createdAt: DateTime.parse(q['created_at'] as String),
          subtopic: subtopicData != null
              ? Subtopic.fromJson(subtopicData)
              : null,
        );
      }).toList();

      setState(() {
        _questions = questions;
        _filteredQuestions = questions;
        _isLoading = false;
      });

      print('✅ Loaded ${questions.length} questions for subtopic ${widget.theoryCard.subtopicId}');
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _speakQuestion(Question question) async {
    HapticFeedback.mediumImpact();
    
    // Stop any custom audio playing
    _stopAllCustomAudio();
    
    // If already speaking this question, stop
    if (_isTtsSpeaking && _currentTtsQuestionId == question.id) {
      _ttsHelper.stop();
      setState(() {
        _isTtsSpeaking = false;
        _currentTtsQuestionId = null;
      });
      return;
    }
    
    // Stop previous TTS if speaking another question
    if (_isTtsSpeaking) {
      _ttsHelper.stop();
    }
    
    final questionLang = _questionLanguages[question.id] ?? 'it';
    final text = question.getText(questionLang);
    
    setState(() {
      _isTtsSpeaking = true;
      _currentTtsQuestionId = question.id;
    });
    
    final success = await _ttsHelper.speak(text, questionLang, awaitCompletion: true);
    
    if (mounted) {
      setState(() {
        _isTtsSpeaking = false;
        _currentTtsQuestionId = null;
      });
    }
  }

  void _stopAllCustomAudio() {
    for (final entry in _audioPlayers.entries) {
      entry.value.pause();
    }
    setState(() {
      _isAudioPlaying.clear();
    });
  }

  Future<void> _toggleCustomAudio(Question question) async {
    HapticFeedback.lightImpact();
    
    final audioUrl = question.explanationAudioUrl;
    if (audioUrl == null || audioUrl.isEmpty) return;
    
    // Stop TTS if speaking
    if (_isTtsSpeaking) {
      _ttsHelper.stop();
      setState(() {
        _isTtsSpeaking = false;
        _currentTtsQuestionId = null;
      });
    }
    
    // Stop other audio players
    for (final entry in _audioPlayers.entries) {
      if (entry.key != question.id) {
        entry.value.pause();
        _isAudioPlaying[entry.key] = false;
      }
    }
    
    // Get or create audio player for this question
    if (!_audioPlayers.containsKey(question.id)) {
      final player = AudioPlayer();
      _audioPlayers[question.id] = player;
      
      player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isAudioPlaying[question.id] = state.playing;
            if (state.playing) _isAudioLoading[question.id] = false;
          });
        }
      });
      
      player.processingStateStream.listen((state) {
        if (mounted) {
          setState(() {
            if (state == ProcessingState.ready) {
              _isAudioLoading[question.id] = false;
            } else if (state == ProcessingState.completed) {
              _isAudioPlaying[question.id] = false;
            }
          });
        }
      });
    }
    
    final player = _audioPlayers[question.id]!;
    
    try {
      if (_isAudioPlaying[question.id] == true) {
        await player.pause();
      } else {
        if (player.audioSource == null) {
          setState(() => _isAudioLoading[question.id] = true);
          await player.setUrl(audioUrl);
        }
        await player.play();
      }
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      setState(() => _isAudioLoading[question.id] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 64),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _cycleLanguage(int questionId) {
    setState(() {
      final currentLang = _questionLanguages[questionId] ?? 'it';
      if (currentLang == 'it') {
        _questionLanguages[questionId] = 'en';
      } else if (currentLang == 'en') {
        _questionLanguages[questionId] = 'bn';
      } else {
        _questionLanguages[questionId] = 'it';
      }
    });
  }

  String _getLanguageDisplayName(int questionId) {
    final lang = _questionLanguages[questionId] ?? 'it';
    switch (lang) {
      case 'it':
        return 'Italiano';
      case 'en':
        return 'English';
      case 'bn':
        return 'বাংলা';
      default:
        return 'Italiano';
    }
  }

  void _filterQuestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = _questions;
      } else {
        _filteredQuestions = _questions.where((question) {
          final textIt = question.textIt.toLowerCase();
          final textEn = question.textEn?.toLowerCase() ?? '';
          final textBn = question.textBn?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return textIt.contains(searchLower) ||
                 textEn.contains(searchLower) ||
                 textBn.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final cardTitle = widget.theoryCard.getLocalizedTitle(languageCode) ?? 
                     widget.theoryCard.titleIt ?? 
                     l10n.theoryCardQuizTitle;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _isSearching
                    ? Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: l10n.searchQuestions,
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: _filterQuestions,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _filteredQuestions = _questions;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cardTitle,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_filteredQuestions.length} ${l10n.totalQuestions}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_questions.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.search, color: theme.colorScheme.onPrimary),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                            ),
                        ],
                      ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.loading,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
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
                                      l10n.errorLoading,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: _loadQuestions,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(l10n.theoryCardListRetry),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredQuestions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isSearching ? Icons.search_off : Icons.quiz_outlined,
                                        size: 64,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _isSearching ? l10n.noResultsFound : l10n.theoryCardQuizEmpty,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildQuestionsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredQuestions.length + 1,
      itemBuilder: (context, questionIndex) {
        // Last item: Practice Quiz button
        if (questionIndex == _filteredQuestions.length) {
          return _buildPracticeQuizButton(theme, l10n);
        }

        final question = _filteredQuestions[questionIndex];
        final showExplanation = _visibleExplanations.contains(question.id);
        final questionLang = _questionLanguages[question.id] ?? 'it';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Number & Text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${questionIndex + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.getText(questionLang),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Images (if any)
                if (question.imageUrl != null || 
                    question.subtopic?.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (question.imageUrl != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showImageDialog(
                                question.imageUrl!,
                                'Question ${questionIndex + 1}',
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: question.imageUrl!,
                                height: 160,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 160,
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (question.imageUrl != null && 
                          question.subtopic?.imageUrl != null)
                        const SizedBox(width: 12),
                      if (question.subtopic?.imageUrl != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showImageDialog(
                                question.subtopic!.imageUrl!,
                                question.subtopic!.getName(languageCode),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: question.subtopic!.imageUrl!,
                                height: 160,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 160,
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Audio Controls Row
                _buildAudioControlsRow(question, theme),

                const SizedBox(width: 12),
                // Language Toggle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _cycleLanguage(question.id);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLanguageDisplayName(question.id),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Answer Display (Always Visible)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: question.isTrue 
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: question.isTrue 
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        question.isTrue 
                            ? Icons.check_circle 
                            : Icons.cancel,
                        color: question.isTrue 
                            ? AppTheme.successGreen 
                            : AppTheme.errorRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.quizCorrectAnswer,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              question.isTrue ? 'VERO' : 'FALSO',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: question.isTrue 
                                    ? AppTheme.successGreen 
                                    : AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Show/Hide Explanation Button
                if (question.explanationIt != null ||
                    question.explanationEn != null ||
                    question.explanationBn != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _toggleExplanation(question.id);
                    },
                    icon: Icon(
                      showExplanation 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      showExplanation 
                          ? l10n.customQuizHideExplanation 
                          : l10n.customQuizShowExplanation,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                      ),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],

                // Explanation Display (Hidden by default)
                if (showExplanation && 
                    (question.explanationIt != null ||
                     question.explanationEn != null ||
                     question.explanationBn != null)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.explanation,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.getExplanation(questionLang) ?? 
                              l10n.customQuizNoExplanation,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticeQuizButton(ThemeData theme, dynamic l10n) {
    final questionCount = _questions.length;
    if (questionCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomQuizScreen(
                  numberOfQuestions: questionCount,
                  hasTimeLimit: false,
                  timeLimit: 0,
                  selectedTopicIds: const [],
                  immediateAnswerFeedback: true,
                  preloadedQuestions: List.from(_questions)..shuffle(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled,
                      color: theme.colorScheme.onPrimary, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Quiz',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$questionCount questions • Immediate feedback',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward,
                      color: theme.colorScheme.onPrimary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControlsRow(Question question, ThemeData theme) {
    final hasCustomAudio = question.explanationAudioUrl != null && 
                           question.explanationAudioUrl!.isNotEmpty;
    final isTtsActive = _isTtsSpeaking && _currentTtsQuestionId == question.id;
    final isCustomAudioActive = _isAudioPlaying[question.id] == true;
    final isCustomAudioLoading = _isAudioLoading[question.id] == true;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.headphones, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Audio',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // TTS Button
            _buildAudioButton(
              theme: theme,
              icon: isTtsActive ? Icons.pause : Icons.play_arrow,
              isActive: isTtsActive,
              isLoading: false,
              onTap: () => _speakQuestion(question),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            // Custom Audio Button
            _buildAudioButton(
              theme: theme,
              icon: isCustomAudioActive ? Icons.stop : Icons.record_voice_over,
              isActive: isCustomAudioActive,
              isLoading: isCustomAudioLoading,
              onTap: hasCustomAudio ? () => _toggleCustomAudio(question) : null,
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? color : (enabled ? color.withOpacity(0.1) : theme.colorScheme.outline.withOpacity(0.1)),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(isActive ? Colors.white : color),
                ),
              )
            : Icon(
                icon,
                color: isActive ? Colors.white : (enabled ? color : theme.colorScheme.outline),
                size: 22,
              ),
      ),
    );
  }
}
