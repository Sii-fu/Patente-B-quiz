import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../l10n/app_localizations.dart';
import '../../models/topic.dart';
import '../../models/question.dart';
import '../../models/subtopic.dart';
import '../../utils/theme.dart';
import '../../services/tts_helper.dart';

class QuizzesListScreen extends StatefulWidget {
  final Topic topic;
  final Color categoryColor;
  final Subtopic? subtopic;

  const QuizzesListScreen({
    super.key,
    required this.topic,
    required this.categoryColor,
    this.subtopic,
  });

  @override
  State<QuizzesListScreen> createState() => _QuizzesListScreenState();
}

class _QuizzesListScreenState extends State<QuizzesListScreen> {
  final _supabase = Supabase.instance.client;
  final TtsHelper _ttsHelper = TtsHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];
  bool _isLoading = true;
  String? _error;
  String _currentLanguage = 'it';
  bool _isSearching = false;
  
  // Track which questions have visible answers
  final Set<int> _visibleAnswers = {};
  
  // Track language for each question individually
  final Map<int, String> _questionLanguages = {};

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
    _loadQuestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _currentLanguage = locale.languageCode;
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      // If subtopic is provided, load only that subtopic's questions
      // Otherwise, load all questions for the topic
      final questionsResponse = widget.subtopic != null
          ? await _supabase
              .from('questions')
              .select('*, subtopics(*)')
              .eq('subtopic_id', widget.subtopic!.id)
              .order('id')
          : await _supabase
              .from('questions')
              .select('*, subtopics(*)')
              .eq('topic_id', widget.topic.id)
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
    } catch (e) {
      debugPrint('Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _speakQuestion(Question question) async {
    HapticFeedback.mediumImpact();
    
    final questionLang = _questionLanguages[question.id] ?? 'it';
    final text = question.getText(questionLang);
    
    final success = await _ttsHelper.speak(text, questionLang);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Playing audio...' : 'Audio not available'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? widget.categoryColor : Colors.orange,
      ),
    );
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

  void _toggleAnswer(int questionId) {
    setState(() {
      if (_visibleAnswers.contains(questionId)) {
        _visibleAnswers.remove(questionId);
      } else {
        _visibleAnswers.add(questionId);
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

  int _getTotalQuestions() {
    return _filteredQuestions.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.categoryColor,
              widget.categoryColor.withValues(alpha: 0.7),
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
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: l10n.searchQuestions,
                                  hintStyle: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
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
                            icon: const Icon(Icons.close, color: Colors.black),
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
                                  widget.subtopic != null
                                      ? widget.subtopic!.getName(_currentLanguage)
                                      : widget.topic.getName('it'),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_getTotalQuestions()} ${l10n.totalQuestions}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                color: widget.categoryColor,
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
                                      label: const Text('Retry'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: widget.categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredQuestions.isEmpty
                              ? Center(
                                  child: Text(
                                    _isSearching ? l10n.noResultsFound : l10n.noQuestionsAvailable,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _filteredQuestions.length,
                                  itemBuilder: (context, questionIndex) {
                                    final question = _filteredQuestions[questionIndex];
                                          final showAnswer = _visibleAnswers.contains(question.id);

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
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Padding(
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
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: widget.categoryColor.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              '${questionIndex + 1}',
                                                              style: TextStyle(
                                                                color: widget.categoryColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              question.getText(_questionLanguages[question.id] ?? 'it'),
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                                color: theme.colorScheme.onSurface,
                                                                height: 1.5,
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
                                                            if (question.subtopic?.imageUrl != null)
                                                              Expanded(
                                                                child: GestureDetector(
                                                                  onTap: () => _showImageDialog(
                                                                    question.subtopic!.imageUrl!,
                                                                    question.subtopic!.getName(_currentLanguage),
                                                                  ),
                                                                  child: Container(
                                                                    height: 120,
                                                                    decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(
                                                                        color: widget.categoryColor.withValues(alpha: 0.3),
                                                                        width: 2,
                                                                      ),
                                                                    ),
                                                                    child: ClipRRect(
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      child: CachedNetworkImage(
                                                                        imageUrl: question.imageUrl!,
                                                                        fit: BoxFit.fitHeight,
                                                                        placeholder: (context, url) => Center(
                                                                          child: CircularProgressIndicator(
                                                                            color: widget.categoryColor,
                                                                            strokeWidth: 2,
                                                                          ),
                                                                        ),
                                                                        errorWidget: (context, url, error) => Icon(
                                                                          Icons.image_not_supported,
                                                                          color: Colors.grey,
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

                                                      // Action Buttons Row
                                                      Row(
                                                        children: [
                                                          // Read Aloud Button
                                                            InkWell(
                                                            onTap: () {
                                                              HapticFeedback.selectionClick();
                                                              _speakQuestion(question);
                                                            },
                                                            borderRadius: BorderRadius.circular(10),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                              ),
                                                              decoration: BoxDecoration(
                                                              color: widget.categoryColor.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(
                                                                color: widget.categoryColor.withValues(alpha: 0.3),
                                                                width: 1.5,
                                                              ),
                                                              ),
                                                              child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                Icons.volume_up,
                                                                color: widget.categoryColor,
                                                                size: 18,
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                l10n.readAloud,
                                                                style: TextStyle(
                                                                  color: widget.categoryColor,
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 13,
                                                                ),
                                                                ),
                                                              ],
                                                              ),
                                                            ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                          // Language Toggle Button
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
                                                                color: widget.categoryColor.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(
                                                                  color: widget.categoryColor.withValues(alpha: 0.3),
                                                                  width: 1.5,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    Icons.translate,
                                                                    color: widget.categoryColor,
                                                                    size: 18,
                                                                  ),
                                                                  SizedBox(width: 6),
                                                                  Text(
                                                                    _getLanguageDisplayName(question.id),
                                                                    style: TextStyle(
                                                                      color: widget.categoryColor,
                                                                      fontWeight: FontWeight.w600,
                                                                      fontSize: 13,
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
                                                        padding: const EdgeInsets.all(10),
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
                                                              size: 32,
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    l10n.answer,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    question.isTrue ? l10n.quizTrue : l10n.quizFalse,
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
                                                            _toggleAnswer(question.id);
                                                          },
                                                          icon: Icon(
                                                            showAnswer 
                                                                ? Icons.visibility_off 
                                                                : Icons.lightbulb_outline,
                                                            size: 18,
                                                            color: widget.categoryColor,
                                                          ),
                                                          label: Text(
                                                            showAnswer 
                                                                ? l10n.customQuizHideExplanation
                                                                : l10n.customQuizShowExplanation,
                                                            style: TextStyle(
                                                              color: widget.categoryColor,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          style: OutlinedButton.styleFrom(
                                                            side: BorderSide(
                                                              color: widget.categoryColor.withValues(alpha: 0.3),
                                                              width: 1.5,
                                                            ),
                                                            minimumSize: const Size(double.infinity, 44),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                          ),
                                                        ),
                                                      ],

                                                      // Explanation Display (Hidden by default)
                                                      if (showAnswer && 
                                                          (question.explanationIt != null ||
                                                           question.explanationEn != null ||
                                                           question.explanationBn != null)) ...[
                                                        const SizedBox(height: 12),
                                                        Container(
                                                          padding: const EdgeInsets.all(16),
                                                          decoration: BoxDecoration(
                                                            color: widget.categoryColor.withValues(alpha: 0.05),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(
                                                              color: widget.categoryColor.withValues(alpha: 0.2),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons.lightbulb,
                                                                    color: widget.categoryColor,
                                                                    size: 20,
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Text(
                                                                    'Spiegazione',
                                                                    style: TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: widget.categoryColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Text(
                                                                question.getExplanation(_questionLanguages[question.id] ?? 'it') ?? '',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: theme.colorScheme.onSurface,
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
                                              ],
                                            ),
                                          );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
