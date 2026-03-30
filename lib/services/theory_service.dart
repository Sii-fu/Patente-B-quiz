import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import '../models/theory_chapter.dart';
import '../models/theory_card.dart';
import 'package:drift/drift.dart' as drift;

/// Service for managing theory content (chapters, cards, progress tracking)
/// Fetches data directly from Supabase (no local DB caching for content)
/// Only progress tracking is stored locally
class TheoryService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
 
  // SharedPreferences keys for progress tracking
  static const String _lastReadChapterKey = 'last_read_chapter_id';
  static const String _lastReadCardKey = 'last_read_card_id';

  TheoryService(this._db, this._supabase);

  // ====== CHAPTER OPERATIONS ======

  /// Get all theory chapters (uses local DB cache if available, otherwise fetches from Supabase)
  Future<List<TheoryChapter>> getAllChapters() async {
    try {
      // Try to load from local DB first (cache)
      final localChapters = await _db.getAllTheoryChapters();
      
      if (localChapters.isNotEmpty) {
        print('📦 Using cached chapters from local DB (${localChapters.length} chapters)');
        return localChapters.map((lc) {
          return TheoryChapter(
            id: lc.id,
            relatedQuizTopicId: lc.relatedQuizTopicId,
            nameIt: lc.nameIt,
            nameEn: lc.nameEn,
            nameBn: lc.nameBn,
            imageUrl: lc.imageUrl,
            displayOrder: lc.displayOrder,
            createdAt: lc.createdAt,
          );
        }).toList();
      }

      // If no local chapters, fetch from Supabase and cache them
      print('📖 No cached chapters, fetching from Supabase...');
      final response = await _supabase
          .from('theory_chapters')
          .select()
          .order('display_order', ascending: true);

      final chapters = (response as List)
          .where((data) => data != null && data['id'] != null)
          .map((data) {
        final dynamic idVal = data['id'];
        final int id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '') ?? 0;

        final displayOrder = (data['display_order'] as int?) ?? 0;

        DateTime createdAt;
        try {
          createdAt = data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : DateTime.now();
        } catch (_) {
          createdAt = DateTime.now();
        }

        return TheoryChapter(
          id: id,
          relatedQuizTopicId: data['related_quiz_topic_id'] as int?,
          nameIt: (data['name_it'] as String?) ?? '',
          nameEn: data['name_en'] as String?,
          nameBn: data['name_bn'] as String?,
          imageUrl: data['image_url'] as String?,
          displayOrder: displayOrder,
          createdAt: createdAt,
        );
      }).toList();

      // Cache chapters in local DB for next time
      print('💾 Caching ${chapters.length} chapters to local DB...');
      for (final chapter in chapters) {
        await _db.upsertTheoryChapter(
          LocalTheoryChaptersCompanion(
            id: drift.Value(chapter.id),
            relatedQuizTopicId: drift.Value(chapter.relatedQuizTopicId),
            nameIt: drift.Value(chapter.nameIt),
            nameEn: drift.Value(chapter.nameEn),
            nameBn: drift.Value(chapter.nameBn),
            imageUrl: drift.Value(chapter.imageUrl),
            displayOrder: drift.Value(chapter.displayOrder),
            createdAt: drift.Value(chapter.createdAt),
          ),
        );
      }
      print('✅ Chapters cached successfully');

      return chapters;
    } catch (e, stackTrace) {
      print('❌ Error fetching chapters: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get a specific chapter by ID directly from Supabase
  Future<TheoryChapter?> getChapterById(int id) async {
    try {
      final response = await _supabase
          .from('theory_chapters')
          .select()
          .eq('id', id)
          .single();

      return TheoryChapter(
        id: response['id'] as int,
        relatedQuizTopicId: response['related_quiz_topic_id'] as int?,
        nameIt: response['name_it'] as String,
        nameEn: response['name_en'] as String?,
        nameBn: response['name_bn'] as String?,
        imageUrl: response['image_url'] as String?,
        displayOrder: response['display_order'] as int,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e) {
      print('❌ Error fetching chapter $id: $e');
      return null;
    }
  }

  // ====== CARD OPERATIONS ======

  /// Get all theory cards for a specific chapter directly from Supabase
  Future<List<TheoryCard>> getCardsForChapter(int chapterId) async {
    try {
      print('🃏 Fetching cards for chapter $chapterId from Supabase...');
      final response = await _supabase
          .from('theory_cards')
          .select()
          .eq('chapter_id', chapterId)
          .order('id', ascending: true);

      final cards = (response as List).map((data) {
        return TheoryCard(
          id: data['id'] as int,
          chapterId: data['chapter_id'] as int,
          subtopicId: data['subtopic_id'] as int?,
          titleIt: data['title_it'] as String?,
          titleEn: data['title_en'] as String?,
          titleBn: data['title_bn'] as String?,
          textIt: data['text_it'] as String,
          textEn: data['text_en'] as String?,
          textBn: data['text_bn'] as String?,
          imageUrl: data['image_url'] as String?,
          displayOrder: data['display_order'] as int,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      print('✅ Fetched ${cards.length} cards for chapter $chapterId');
      return cards;
    } catch (e, stackTrace) {
      print('❌ Error fetching cards: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all theory cards from all chapters directly from Supabase
  Future<List<TheoryCard>> getAllCards() async {
    try {
      print('🃏 Fetching all theory cards from Supabase...');
      final response = await _supabase
          .from('theory_cards')
          .select()
          .order('id', ascending: true);

      final cards = (response as List).map((data) {
        return TheoryCard(
          id: data['id'] as int,
          chapterId: data['chapter_id'] as int,
          subtopicId: data['subtopic_id'] as int?,
          titleIt: data['title_it'] as String?,
          titleEn: data['title_en'] as String?,
          titleBn: data['title_bn'] as String?,
          textIt: data['text_it'] as String,
          textEn: data['text_en'] as String?,
          textBn: data['text_bn'] as String?,
          imageUrl: data['image_url'] as String?,
          displayOrder: data['display_order'] as int,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      print('✅ Fetched ${cards.length} total theory cards');
      return cards;
    } catch (e, stackTrace) {
      print('❌ Error fetching all cards: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get total card count for a chapter directly from Supabase
  Future<int> getCardCountForChapter(int chapterId) async {
    try {
      final response = await _supabase
          .from('theory_cards')
          .select('id')
          .eq('chapter_id', chapterId);
      
      return (response as List).length;
    } catch (e) {
      print('❌ Error getting card count: $e');
      return 0;
    }
  }

  // ====== PROGRESS TRACKING ======

  /// Mark a specific card as read
  Future<void> markCardAsRead(int chapterId, int cardId) async {
    await _db.markCardAsRead(chapterId, cardId);
    await _saveLastReadPosition(chapterId, cardId);
  }

  /// Get progress percentage for a chapter (0-100)
  Future<double> getChapterProgress(int chapterId) async {
    return await _db.getChapterProgress(chapterId);
  }

  /// Get read card IDs for a chapter
  Future<List<int>> getReadCardIds(int chapterId) async {
    return await _db.getReadCardIds(chapterId);
  }

  /// Check if a specific card has been read
  Future<bool> isCardRead(int chapterId, int cardId) async {
    final readCards = await getReadCardIds(chapterId);
    return readCards.contains(cardId);
  }

  /// Get chapter completion status for all chapters
  /// Returns Map<chapterId, progressPercentage>
  Future<Map<int, double>> getAllChapterProgress() async {
    final chapters = await getAllChapters();
    final progressMap = <int, double>{};

    for (final chapter in chapters) {
      progressMap[chapter.id] = await getChapterProgress(chapter.id);
    }

    return progressMap;
  }

  // ====== LAST READ POSITION ======

  /// Save the last read position (chapter + card)
  Future<void> _saveLastReadPosition(int chapterId, int cardId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadChapterKey, chapterId);
    await prefs.setInt(_lastReadCardKey, cardId);
  }

  /// Get the last read chapter ID
  Future<int?> getLastReadChapterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadChapterKey);
  }

  /// Get the last read card ID
  Future<int?> getLastReadCardId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadCardKey);
  }

  /// Get last read chapter and card index
  /// Returns (chapterId, cardIndex) or null if no history
  Future<(int, int)?> getLastReadPosition() async {
    final chapterId = await getLastReadChapterId();
    if (chapterId == null) return null;

    final cardId = await getLastReadCardId();
    if (cardId == null) return null;

    // Get all cards for the chapter to find the index
    final cards = await getCardsForChapter(chapterId);
    final cardIndex = cards.indexWhere((c) => c.id == cardId);
    
    if (cardIndex == -1) return null;

    return (chapterId, cardIndex);
  }

  // ====== STATS & ANALYTICS ======

  /// Get overall theory progress (all chapters combined)
  Future<double> getOverallProgress() async {
    final chapters = await getAllChapters();
    if (chapters.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final chapter in chapters) {
      totalProgress += await getChapterProgress(chapter.id);
    }

    return totalProgress / chapters.length;
  }

  /// Get count of completed chapters (100% progress)
  Future<int> getCompletedChaptersCount() async {
    final progressMap = await getAllChapterProgress();
    return progressMap.values.where((progress) => progress >= 100.0).length;
  }

  /// Clear all progress (for reset/debug)
  Future<void> clearAllProgress() async {
    await _db.clearTheoryProgress();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastReadChapterKey);
    await prefs.remove(_lastReadCardKey);
  }

  // ====== CONVENIENCE METHODS ======

  /// Get chapter with progress info
  Future<ChapterWithProgress> getChapterWithProgress(int chapterId) async {
    final chapter = await getChapterById(chapterId);
    if (chapter == null) {
      throw Exception('Chapter not found: $chapterId');
    }

    final progress = await getChapterProgress(chapterId);
    final totalCards = await getCardCountForChapter(chapterId);
    final readCards = await getReadCardIds(chapterId);

    return ChapterWithProgress(
      chapter: chapter,
      progressPercentage: progress,
      totalCards: totalCards,
      readCardsCount: readCards.length,
    );
  }

  /// Get all chapters with their progress (optimized - fetches all data in bulk)
  Future<List<ChapterWithProgress>> getAllChaptersWithProgress() async {
    print('📊 Fetching all chapters with progress (optimized)...');
    
    // Step 1: Get all chapters (cached locally, fast)
    final chapters = await getAllChapters();
    if (chapters.isEmpty) return [];
    
    // Step 2: Get all card counts in ONE query
    print('📊 Fetching card counts for all chapters...');
    final cardCountsResponse = await _supabase
        .from('theory_cards')
        .select('chapter_id')
        .inFilter('chapter_id', chapters.map((c) => c.id).toList());
    
    final cardCountsMap = <int, int>{};
    for (final row in cardCountsResponse as List) {
      final chapterId = row['chapter_id'] as int;
      cardCountsMap[chapterId] = (cardCountsMap[chapterId] ?? 0) + 1;
    }
    
    // Step 3: Get all read cards from local DB in ONE query
    print('📊 Fetching read progress from local DB...');
    final allReadCards = await _db.getAllTheoryProgress();
    
    // Group by chapter
    final readCardsMap = <int, Set<int>>{};
    for (final progress in allReadCards) {
      readCardsMap.putIfAbsent(progress.chapterId, () => <int>{}).add(progress.cardId);
    }
    
    // Step 4: Build results (all in memory, super fast)
    final results = <ChapterWithProgress>[];
    for (final chapter in chapters) {
      final totalCards = cardCountsMap[chapter.id] ?? 0;
      final readCards = readCardsMap[chapter.id]?.length ?? 0;
      final progress = totalCards > 0 ? (readCards / totalCards * 100) : 0.0;
      
      results.add(ChapterWithProgress(
        chapter: chapter,
        progressPercentage: progress,
        totalCards: totalCards,
        readCardsCount: readCards,
      ));
    }

    print('✅ Completed progress fetch for ${results.length} chapters in 3 queries (was ${chapters.length * 4})');
    return results;
  }

  /// Fast chapter summary fetch directly from Supabase (no local DB, minimal fields)
  /// Returns only id, names and display order to make listing very fast.
  Future<List<TheoryChapter>> getChapterSummariesFast() async {
    try {
      print('🚀 Fetching chapter summaries (fast) from Supabase...');
        final response = await _supabase
          .from('theory_chapters')
          .select('id, related_quiz_topic_id, name_it, name_en, name_bn, display_order, created_at')
          .order('id', ascending: true);

      final chapters = (response as List)
          .where((data) => data != null && data['id'] != null)
          .map((data) {
        final dynamic idVal = data['id'];
        final int id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '') ?? 0;

        final displayOrder = (data['display_order'] is int)
            ? data['display_order'] as int
            : int.tryParse(data['display_order']?.toString() ?? '') ?? 0;

        DateTime createdAt;
        try {
          createdAt = data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : DateTime.now();
        } catch (_) {
          createdAt = DateTime.now();
        }

        return TheoryChapter(
          id: id,
          relatedQuizTopicId: data['related_quiz_topic_id'] as int?,
          nameIt: (data['name_it'] as String?) ?? '',
          nameEn: data['name_en'] as String?,
          nameBn: data['name_bn'] as String?,
          imageUrl: data['image_url'] as String?,
          displayOrder: displayOrder,
          createdAt: createdAt,
        );
      }).toList();

      print('✅ Fetched ${chapters.length} chapter summaries');
      return chapters;
    } catch (e, stackTrace) {
      print('❌ Error fetching chapter summaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

/// Data class combining chapter info with progress
class ChapterWithProgress {
  final TheoryChapter chapter;
  final double progressPercentage;
  final int totalCards;
  final int readCardsCount;

  ChapterWithProgress({
    required this.chapter,
    required this.progressPercentage,
    required this.totalCards,
    required this.readCardsCount,
  });

  bool get isCompleted => progressPercentage >= 100.0;
  bool get isInProgress => progressPercentage > 0.0 && progressPercentage < 100.0;
  bool get isNotStarted => progressPercentage == 0.0;
}
