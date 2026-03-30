import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/theory_chapter.dart';
import '../../services/theory_service.dart';
import '../../database/database_provider.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theory_reading_screen.dart';
import '../theory/theory_card_list_screen.dart';

/// Page 1: Theory Chapters List
/// Shows "Continue Learning" card + all chapters with progress indicators
class TheoryChaptersScreen extends StatefulWidget {
  const TheoryChaptersScreen({super.key});

  @override
  State<TheoryChaptersScreen> createState() => _TheoryChaptersScreenState();
}

class _TheoryChaptersScreenState extends State<TheoryChaptersScreen> {
  late TheoryService _theoryService;
  List<ChapterWithProgress> _chapters = [];
  ChapterWithProgress? _continueChapter;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      final db = DatabaseProvider.instance;
      final supabase = Supabase.instance.client;
      _theoryService = TheoryService(db, supabase);

      await _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load theory content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📥 Loading chapter summaries (fast) from Supabase...');

      // Fast load: fetch only chapter id, names and display order directly from Supabase
      final rawChapters = await _theoryService.getChapterSummariesFast();
      final chapters = rawChapters.map((ch) {
        return ChapterWithProgress(
          chapter: ch,
          progressPercentage: 0.0,
          totalCards: 0,
          readCardsCount: 0,
        );
      }).toList();
      print('🎯 Loaded ${chapters.length} chapters (fast)');

      // Get last read chapter for "Continue Learning"
      final lastReadChapterId = await _theoryService.getLastReadChapterId();
      ChapterWithProgress? continueChapter;

      if (lastReadChapterId != null) {
        continueChapter = chapters.firstWhere(
          (c) => c.chapter.id == lastReadChapterId,
          orElse: () => chapters.first,
        );
      } else if (chapters.isNotEmpty) {
        // If no history, show first chapter
        continueChapter = chapters.first;
      }

      setState(() {
        _chapters = chapters;
        _continueChapter = continueChapter;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading chapters: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToChapter(int chapterId, {int startCardIndex = 0}) async {
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TheoryReadingScreen(
          chapterId: chapterId,
          initialCardIndex: startCardIndex,
        ),
      ),
    );

    // Reload progress after returning
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text( 
          'ALL THEORY',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Loading Text
                    Text(
                      'Loading theory content...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing your study materials',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Animated Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                        minHeight: 6,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Additional Encouragement Text
                    Text(
                      '📚 Get ready to learn!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
    
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Continue Learning Section
          if (_continueChapter != null) ...[
            _buildSectionHeader('Continue Learning'),
            const SizedBox(height: 12),
            _buildContinueLearningCard(_continueChapter!),
            const SizedBox(height: 32),
          ],

          // All Chapters Section
          _buildSectionHeader('All Chapters'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              childAspectRatio: 3.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _chapters.length,
            itemBuilder: (context, i) => _buildChapterCard(_chapters[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
    );
  }


  Widget _buildContinueLearningCard(ChapterWithProgress chapterProgress) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final chapterName = chapterProgress.chapter.getLocalizedName(languageCode);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Resume from last read position
          final lastPosition = await _theoryService.getLastReadPosition();
          final startIndex = lastPosition?.$2 ?? 0;
          await _navigateToChapter(chapterProgress.chapter.id, startCardIndex: startIndex);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                    'Lezione ${chapterProgress.chapter.id}: $chapterName',
                      style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Resume Play Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: chapterProgress.progressPercentage / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  color: AppTheme.successGreen,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              // Progress Text
              Text(
                '${chapterProgress.progressPercentage.toStringAsFixed(0)}% Completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(ChapterWithProgress chapterProgress) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final primaryName = chapterProgress.chapter.getLocalizedName('it'); // Always show Italian
    final theme = Theme.of(context);
    
    // Show English/Bangla as secondary based on current language
    String secondaryName = '';
    if (languageCode == 'en' && chapterProgress.chapter.nameEn != null) {
      secondaryName = chapterProgress.chapter.nameEn!;
    } else if (languageCode == 'bn' && chapterProgress.chapter.nameBn != null) {
      secondaryName = chapterProgress.chapter.nameBn!;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToChapter(chapterProgress.chapter.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Chapter Number
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                  child: Center(
                  child: Text(
                    chapterProgress.chapter.id.toString().padLeft(2, '0'),
                    style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Chapter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        secondaryName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status Indicator
              _buildStatusIndicator(chapterProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ChapterWithProgress chapterProgress) {
    final theme = Theme.of(context);
    if (chapterProgress.isCompleted) {
      // Completed: Green checkmark
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          color: AppTheme.successGreen,
          size: 24,
        ),
      );
    } else if (chapterProgress.isInProgress) {
      // In Progress: Circular progress indicator
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: chapterProgress.progressPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              color: AppTheme.successGreen,
              strokeWidth: 4,
            ),
            Text(
              '${chapterProgress.progressPercentage.toInt()}',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    } else {
      // Not Started: Empty circle
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
        ),
      );
    }
  }
}
