import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/theory_chapter.dart';
import '../models/theory_card.dart';

/// Service for managing theory content (chapters, cards, progress tracking)
/// 100% Online - Fetches all data directly from Supabase
/// Progress tracking is stored locally via SharedPreferences
class TheoryService {
  final SupabaseClient _supabase;
 
  // SharedPreferences keys for progress tracking
  static const String _lastReadChapterKey = 'last_read_chapter_id';
  static const String _lastReadCardKey = 'last_read_card_id';
  static const String _readCardsKey = 'theory_read_cards'; // Map<chapterId, List<cardId>>

  TheoryService(this._supabase);
  
  /// Factory constructor for easy initialization without AppDatabase
  factory TheoryService.online({SupabaseClient? supabaseClient}) {
    return TheoryService(supabaseClient ?? Supabase.instance.client);
  }

  // ====== CHAPTER OPERATIONS ======

  /// Get all theory chapters directly from Supabase
  Future<List<TheoryChapter>> getAllChapters() async {
    try {
      print('📖 Fetching chapters from Supabase...');
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

      print('✅ Loaded ${chapters.length} chapters from Supabase');
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
          audioExplanationUrl: data['audio_explanation_url'] as String?,
          audioItUrl: data['audio_it_url'] as String?,
          audioEnUrl: data['audio_en_url'] as String?,
          audioBnUrl: data['audio_bn_url'] as String?,
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
          audioExplanationUrl: data['audio_explanation_url'] as String?,
          audioItUrl: data['audio_it_url'] as String?,
          audioEnUrl: data['audio_en_url'] as String?,
          audioBnUrl: data['audio_bn_url'] as String?,
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

  // ====== PROGRESS TRACKING (SharedPreferences) ======

  /// Get all read cards data from SharedPreferences
  Future<Map<int, Set<int>>> _getAllReadCardsData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_readCardsKey);
    if (jsonStr == null) return {};
    
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      final result = <int, Set<int>>{};
      decoded.forEach((key, value) {
        final chapterId = int.tryParse(key);
        if (chapterId != null && value is List) {
          result[chapterId] = value.map((e) => e as int).toSet();
        }
      });
      return result;
    } catch (e) {
      print('❌ Error parsing read cards data: $e');
      return {};
    }
  }

  /// Save all read cards data to SharedPreferences
  Future<void> _saveAllReadCardsData(Map<int, Set<int>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<int>> toEncode = {};
    data.forEach((chapterId, cardIds) {
      toEncode[chapterId.toString()] = cardIds.toList();
    });
    await prefs.setString(_readCardsKey, json.encode(toEncode));
  }

  /// Mark a specific card as read
  Future<void> markCardAsRead(int chapterId, int cardId) async {
    final allData = await _getAllReadCardsData();
    allData.putIfAbsent(chapterId, () => <int>{}).add(cardId);
    await _saveAllReadCardsData(allData);
    await _saveLastReadPosition(chapterId, cardId);
  }

  /// Get progress percentage for a chapter (0-100)
  Future<double> getChapterProgress(int chapterId) async {
    final totalCards = await getCardCountForChapter(chapterId);
    if (totalCards == 0) return 0.0;
    
    final readCards = await getReadCardIds(chapterId);
    return (readCards.length / totalCards) * 100;
  }

  /// Get read card IDs for a chapter
  Future<List<int>> getReadCardIds(int chapterId) async {
    final allData = await _getAllReadCardsData();
    return allData[chapterId]?.toList() ?? [];
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readCardsKey);
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
    
    // Step 1: Get all chapters from Supabase
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
    
    // Step 3: Get all read cards from SharedPreferences
    print('📊 Fetching read progress from SharedPreferences...');
    final readCardsMap = await _getAllReadCardsData();
    
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

    print('✅ Completed progress fetch for ${results.length} chapters');
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
