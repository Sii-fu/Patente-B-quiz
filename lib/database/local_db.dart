import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_db.g.dart';

// ====== TABLE DEFINITIONS ======

/// Categories table (e.g., "Segnali di pericolo", "Precedenza")
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalCategory')
class LocalCategories extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get nameBn => text().named('name_bn')();
  TextColumn get colorHex => text().named('color_hex')();
  IntColumn get displayOrder => integer().named('display_order')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Topics table (e.g., "Segnali di divieto", "Limiti di velocità")
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalTopic')
class LocalTopics extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  IntColumn get categoryId => integer().named('category_id')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get nameBn => text().named('name_bn')();
  TextColumn get imageUrl => text().named('image_url').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Subtopics table (e.g., specific sign types under a topic)
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalSubtopic')
class LocalSubtopics extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  IntColumn get topicId => integer().named('topic_id')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get imageUrl => text().named('image_url').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Questions table (true/false quiz questions)
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalQuestion')
class LocalQuestions extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  IntColumn get subtopicId => integer().named('subtopic_id')();
  TextColumn get textIt => text().named('text_it')();
  TextColumn get textEn => text().named('text_en')();
  TextColumn get textBn => text().named('text_bn')();
  TextColumn get imageUrl => text().named('image_url').nullable()();
  BoolColumn get isTrue => boolean().named('is_true')();
  TextColumn get explanationIt => text().named('explanation_it').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table to store quiz results taken while offline
/// ID is auto-increment (local tracking only)
@DataClassName('PendingUpload')
class PendingUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get apiEndpoint => text().named('api_endpoint')();
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

/// Theory Chapters table (e.g., "Lezione 1: Definizioni Stradali")
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalTheoryChapter')
class LocalTheoryChapters extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  IntColumn get relatedQuizTopicId => integer().named('related_quiz_topic_id').nullable()();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameEn => text().named('name_en').nullable()();
  TextColumn get nameBn => text().named('name_bn').nullable()();
  TextColumn get imageUrl => text().named('image_url').nullable()();
  IntColumn get displayOrder => integer().named('display_order')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Theory Cards table (e.g., "DOSSO", "CUNETTA")
/// IDs are manually set to match Supabase IDs (no autoIncrement)
@DataClassName('LocalTheoryCard')
class LocalTheoryCards extends Table {
  // Manual ID (must match Supabase)
  IntColumn get id => integer()();
  IntColumn get chapterId => integer().named('chapter_id')();
  IntColumn get subtopicId => integer().named('subtopic_id').nullable()();
  TextColumn get titleIt => text().named('title_it').nullable()();
  TextColumn get titleEn => text().named('title_en').nullable()();
  TextColumn get titleBn => text().named('title_bn').nullable()();
  TextColumn get textIt => text().named('text_it')();
  TextColumn get textEn => text().named('text_en').nullable()();
  TextColumn get textBn => text().named('text_bn').nullable()();
  TextColumn get imageUrl => text().named('image_url').nullable()();
  IntColumn get displayOrder => integer().named('display_order')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Theory Progress table (local tracking of read cards)
/// Stores which cards have been read and chapter progress
@DataClassName('TheoryProgress')
class TheoryProgressTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().named('chapter_id')();
  IntColumn get cardId => integer().named('card_id')();
  BoolColumn get isRead => boolean().named('is_read').withDefault(const Constant(false))();
  DateTimeColumn get lastReadAt => dateTime().named('last_read_at').nullable()();
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {chapterId, cardId}, // Prevent duplicate entries for same chapter + card
  ];
}

// ====== DATABASE CLASS ======

@DriftDatabase(tables: [
  LocalCategories,
  LocalTopics,
  LocalSubtopics,
  LocalQuestions,
  PendingUploads,
  LocalTheoryChapters,
  LocalTheoryCards,
  TheoryProgressTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented for new tables

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add theory tables in version 2
          await m.createTable(localTheoryChapters);
          await m.createTable(localTheoryCards);
          await m.createTable(theoryProgressTable);
        }
      },
    );
  }

  // ====== HELPER METHODS ======

  /// Save offline quiz result for later sync
  Future<int> saveOfflineResult(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final jsonPayload = jsonEncode(data);
    
    return await into(pendingUploads).insert(
      PendingUploadsCompanion.insert(
        apiEndpoint: endpoint,
        payload: jsonPayload,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Get all pending uploads (for sync)
  Future<List<PendingUpload>> getAllPendingUploads() async {
    return await select(pendingUploads).get();
  }

  /// Delete a pending upload after successful sync
  Future<int> deletePendingUpload(int id) async {
    return await (delete(pendingUploads)..where((u) => u.id.equals(id))).go();
  }

  // ====== CATEGORY OPERATIONS ======

  /// Get all categories ordered by display_order
  Future<List<LocalCategory>> getAllCategories() async {
    return await (select(localCategories)
          ..orderBy([(c) => OrderingTerm(expression: c.displayOrder)]))
        .get();
  }

  /// Insert or replace a category (for sync)
  Future<void> upsertCategory(LocalCategoriesCompanion category) async {
    await into(localCategories).insertOnConflictUpdate(category);
  }

  // ====== TOPIC OPERATIONS ======

  /// Get topics by category ID
  Future<List<LocalTopic>> getTopicsByCategory(int categoryId) async {
    return await (select(localTopics)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
  }

  /// Insert or replace a topic (for sync)
  Future<void> upsertTopic(LocalTopicsCompanion topic) async {
    await into(localTopics).insertOnConflictUpdate(topic);
  }

  // ====== SUBTOPIC OPERATIONS ======

  /// Get subtopics by topic ID
  Future<List<LocalSubtopic>> getSubtopicsByTopic(int topicId) async {
    return await (select(localSubtopics)
          ..where((s) => s.topicId.equals(topicId)))
        .get();
  }

  /// Insert or replace a subtopic (for sync)
  Future<void> upsertSubtopic(LocalSubtopicsCompanion subtopic) async {
    await into(localSubtopics).insertOnConflictUpdate(subtopic);
  }

  // ====== QUESTION OPERATIONS ======

  /// Get questions by subtopic ID
  Future<List<LocalQuestion>> getQuestionsBySubtopic(int subtopicId) async {
    return await (select(localQuestions)
          ..where((q) => q.subtopicId.equals(subtopicId)))
        .get();
  }

  /// Get questions for multiple subtopics in a single query (batch operation)
  /// Much more efficient than calling getQuestionsBySubtopic in a loop
  Future<List<LocalQuestion>> getQuestionsBySubtopics(List<int> subtopicIds) async {
    if (subtopicIds.isEmpty) return [];
    
    // Use WHERE IN clause for batch query
    return await (select(localQuestions)
          ..where((q) => q.subtopicId.isIn(subtopicIds)))
        .get();
  }

  /// Get questions for all subtopics under a specific topic (optimized)
  Future<List<LocalQuestion>> getQuestionsByTopicId(int topicId) async {
    // First get subtopic IDs for this topic
    final subtopics = await getSubtopicsByTopic(topicId);
    final subtopicIds = subtopics.map((s) => s.id).toList();
    
    if (subtopicIds.isEmpty) return [];
    
    // Use batch query instead of loop
    return await getQuestionsBySubtopics(subtopicIds);
  }

  /// Get random questions for exam mode (30 questions)
  Future<List<LocalQuestion>> getRandomQuestions(int count) async {
    // Note: SQLite doesn't have a built-in RANDOM() in all cases,
    // so we'll fetch all and shuffle in Dart for simplicity
    final allQuestions = await select(localQuestions).get();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  /// Insert or replace a question (for sync)
  Future<void> upsertQuestion(LocalQuestionsCompanion question) async {
    await into(localQuestions).insertOnConflictUpdate(question);
  }

  // ====== BULK SYNC OPERATIONS ======

  /// Clear all data (for full re-sync)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(localQuestions).go();
      await delete(localSubtopics).go();
      await delete(localTopics).go();
      await delete(localCategories).go();
    });
  }

  /// Get total question count (for diagnostics)
  Future<int> getTotalQuestionCount() async {
    final countQuery = selectOnly(localQuestions)
      ..addColumns([localQuestions.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(localQuestions.id.count()) ?? 0;
  }

  /// Get question count for a specific subtopic (efficient count-only query)
  Future<int> getQuestionCountBySubtopic(int subtopicId) async {
    final countQuery = selectOnly(localQuestions)
      ..addColumns([localQuestions.id.count()])
      ..where(localQuestions.subtopicId.equals(subtopicId));
    final result = await countQuery.getSingle();
    return result.read(localQuestions.id.count()) ?? 0;
  }

  /// Get question counts for multiple subtopics in batch (more efficient)
  Future<Map<int, int>> getQuestionCountsForSubtopics(List<int> subtopicIds) async {
    if (subtopicIds.isEmpty) return {};
    
    final counts = <int, int>{};
    for (final subtopicId in subtopicIds) {
      counts[subtopicId] = await getQuestionCountBySubtopic(subtopicId);
    }
    return counts;
  }

  // ====== THEORY CHAPTER OPERATIONS ======

  /// Get all theory chapters ordered by display_order
  Future<List<LocalTheoryChapter>> getAllTheoryChapters() async {
    return await (select(localTheoryChapters)
          ..orderBy([(c) => OrderingTerm(expression: c.displayOrder)]))
        .get();
  }

  /// Get a specific theory chapter by ID
  Future<LocalTheoryChapter?> getTheoryChapterById(int id) async {
    return await (select(localTheoryChapters)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a theory chapter (for sync)
  Future<void> upsertTheoryChapter(LocalTheoryChaptersCompanion chapter) async {
    await into(localTheoryChapters).insertOnConflictUpdate(chapter);
  }

  // ====== THEORY CARD OPERATIONS ======

  /// Get theory cards by chapter ID, ordered by display_order
  Future<List<LocalTheoryCard>> getTheoryCardsByChapter(int chapterId) async {
    return await (select(localTheoryCards)
          ..where((c) => c.chapterId.equals(chapterId))
          ..orderBy([(c) => OrderingTerm(expression: c.displayOrder)]))
        .get();
  }

  /// Get total card count for a chapter
  Future<int> getCardCountByChapter(int chapterId) async {
    final countQuery = selectOnly(localTheoryCards)
      ..addColumns([localTheoryCards.id.count()])
      ..where(localTheoryCards.chapterId.equals(chapterId));
    final result = await countQuery.getSingle();
    return result.read(localTheoryCards.id.count()) ?? 0;
  }

  /// Insert or replace a theory card (for sync)
  Future<void> upsertTheoryCard(LocalTheoryCardsCompanion card) async {
    await into(localTheoryCards).insertOnConflictUpdate(card);
  }

  // ====== THEORY PROGRESS OPERATIONS ======

  /// Mark a card as read
  Future<void> markCardAsRead(int chapterId, int cardId) async {
    await into(theoryProgressTable).insert(
      TheoryProgressTableCompanion.insert(
        chapterId: chapterId,
        cardId: cardId,
        isRead: const Value(true),
        lastReadAt: Value(DateTime.now()),
      ),
      mode: InsertMode.replace,
    );
  }

  /// Get read card IDs for a chapter
  Future<List<int>> getReadCardIds(int chapterId) async {
    final query = select(theoryProgressTable)
      ..where((p) => p.chapterId.equals(chapterId) & p.isRead.equals(true));
    final results = await query.get();
    return results.map((p) => p.cardId).toList();
  }

  /// Get ALL theory progress for all chapters (optimized for bulk loading)
  Future<List<TheoryProgress>> getAllTheoryProgress() async {
    return await select(theoryProgressTable).get();
  }

  /// Get chapter progress (percentage of cards read)
  Future<double> getChapterProgress(int chapterId) async {
    final totalCards = await getCardCountByChapter(chapterId);
    if (totalCards == 0) return 0.0;

    final readCards = await getReadCardIds(chapterId);
    return (readCards.length / totalCards) * 100;
  }

  /// Get last read chapter ID
  Future<int?> getLastReadChapterId() async {
    final query = select(theoryProgressTable)
      ..orderBy([(p) => OrderingTerm(expression: p.lastReadAt, mode: OrderingMode.desc)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.chapterId;
  }

  /// Clear theory progress (for reset)
  Future<void> clearTheoryProgress() async {
    await delete(theoryProgressTable).go();
  }
}

// ====== DATABASE CONNECTION ======

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'patente_b_local.db'));
    
    return NativeDatabase(file);
  });
}
