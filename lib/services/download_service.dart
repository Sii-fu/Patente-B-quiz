import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import '../models/download_state.dart';
import 'cache_version_manager.dart';

/// Service for downloading and syncing content from Supabase to local database
/// Supports offline-first architecture with image prefetching
class DownloadService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final DefaultCacheManager _cacheManager;
  late final CacheVersionManager _versionManager;
  
  static const String _contentDownloadedKey = 'is_content_downloaded'; // Legacy key
  static const String _downloadStateKey = 'download_state';
  static const String _downloadErrorKey = 'download_error_message';
  static const String _downloadTimestampKey = 'download_timestamp';

  DownloadService({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    DefaultCacheManager? cacheManager,
  })  : _db = database,
        _supabase = supabaseClient ?? Supabase.instance.client,
        _cacheManager = cacheManager ?? DefaultCacheManager() {
    _versionManager = CacheVersionManager(supabaseClient: _supabase);
  }

  /// Download all content from Supabase and save to local database
  /// Returns a stream of progress updates (0.0 to 1.0)
  Stream<DownloadProgress> downloadAllContent() async* {
    try {
      // Mark download as in progress
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadStateKey, DownloadState.inProgress.value);
      await prefs.remove(_downloadErrorKey); // Clear any previous error
      
      // Step 1: Fetch data from Supabase (20% of total progress)
      yield DownloadProgress(
        progress: 0.0,
        stage: DownloadStage.fetchingData,
        message: 'Connecting to server...',
      );

      final categories = await _fetchCategories();
      yield DownloadProgress(
        progress: 0.05,
        stage: DownloadStage.fetchingData,
        message: 'Downloaded ${categories.length} categories',
      );

      final topics = await _fetchTopics();
      yield DownloadProgress(
        progress: 0.10,
        stage: DownloadStage.fetchingData,
        message: 'Downloaded ${topics.length} topics',
      );

      final subtopics = await _fetchSubtopics();
      yield DownloadProgress(
        progress: 0.15,
        stage: DownloadStage.fetchingData,
        message: 'Downloaded ${subtopics.length} subtopics',
      );

      final questions = await _fetchQuestions();
      yield DownloadProgress(
        progress: 0.20,
        stage: DownloadStage.fetchingData,
        message: 'Downloaded ${questions.length} questions',
      );

      // Step 2: Batch insert into local database (30% of total progress)
      yield DownloadProgress(
        progress: 0.20,
        stage: DownloadStage.savingToDatabase,
        message: 'Saving to local database...',
      );

      await _batchInsertData(categories, topics, subtopics, questions);

      yield DownloadProgress(
        progress: 0.50,
        stage: DownloadStage.savingToDatabase,
        message: 'Database updated successfully',
      );

      // Step 3: Prefetch images (50% of total progress)
      yield DownloadProgress(
        progress: 0.50,
        stage: DownloadStage.downloadingImages,
        message: 'Preparing image downloads...',
      );

      final imageUrls = _extractImageUrls(topics, subtopics, questions);
      
      if (imageUrls.isEmpty) {
        yield DownloadProgress(
          progress: 1.0,
          stage: DownloadStage.completed,
          message: 'Download completed (no images)',
        );
        return;
      }

      // Download images with progress updates
      await for (final imageProgress in _prefetchImages(imageUrls)) {
        // Map image progress (0.0-1.0) to overall progress (0.5-1.0)
        final overallProgress = 0.50 + (imageProgress.progress * 0.50);
        yield DownloadProgress(
          progress: overallProgress,
          stage: DownloadStage.downloadingImages,
          message: imageProgress.message,
        );
      }

      // Step 4: Complete - Mark content as downloaded
      // Get server version and save to local cache
      final serverVersion = await _versionManager.getServerVersion();
      await _versionManager.setLocalVersion(serverVersion);
      
      await prefs.setString(_downloadStateKey, DownloadState.completed.value);
      await prefs.setBool(_contentDownloadedKey, true); // Keep legacy key for compatibility
      await prefs.setString(_downloadTimestampKey, DateTime.now().toIso8601String());
      await prefs.remove(_downloadErrorKey); // Clear any error

      yield DownloadProgress(
        progress: 1.0,
        stage: DownloadStage.completed,
        message: 'All content downloaded successfully',
      );
    } catch (e, stackTrace) {
      // Mark download as failed and save error message
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadStateKey, DownloadState.failed.value);
      await prefs.setString(_downloadErrorKey, e.toString());
      
      yield DownloadProgress(
        progress: 0.0,
        stage: DownloadStage.error,
        message: 'Error: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  // ====== FETCH DATA FROM SUPABASE ======

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchTopics() async {
    final response = await _supabase.from('topics').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchSubtopics() async {
    final response = await _supabase.from('subtopics').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    final response = await _supabase.from('questions').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // ====== BATCH INSERT INTO LOCAL DATABASE ======

  Future<void> _batchInsertData(
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> topics,
    List<Map<String, dynamic>> subtopics,
    List<Map<String, dynamic>> questions,
  ) async {
    await _db.transaction(() async {
      // Insert categories
      for (final category in categories) {
        try {
          await _db.upsertCategory(
            LocalCategoriesCompanion(
              id: drift.Value(category['id'] as int),
              nameIt: drift.Value(category['name_it'] as String),
              nameEn: drift.Value(category['name_en'] as String),
              nameBn: drift.Value(category['name_bn'] as String),
              colorHex: drift.Value(category['color_hex'] as String),
              displayOrder: drift.Value((category['display_order'] as int?) ?? 0),
            ),
          );
        } catch (e) {
          print('Error inserting category: $category');
          print('Error details: $e');
          rethrow;
        }
      }

      // Insert topics
      for (final topic in topics) {
        try {
          await _db.upsertTopic(
            LocalTopicsCompanion(
              id: drift.Value(topic['id'] as int),
              categoryId: drift.Value(topic['category_id'] as int),
              nameIt: drift.Value(topic['name_it'] as String),
              nameEn: drift.Value(topic['name_en'] as String? ?? ''),
              nameBn: drift.Value(topic['name_bn'] as String? ?? ''),
              imageUrl: drift.Value(topic['image_url'] as String?),
            ),
          );
        } catch (e) {
          print('Error inserting topic: $topic');
          print('Error details: $e');
          rethrow;
        }
      }

      // Insert subtopics
      for (final subtopic in subtopics) {
        try {
          await _db.upsertSubtopic(
            LocalSubtopicsCompanion(
              id: drift.Value(subtopic['id'] as int),
              topicId: drift.Value(subtopic['topic_id'] as int),
              nameIt: drift.Value(subtopic['name_it'] as String),
              imageUrl: drift.Value(subtopic['image_url'] as String?),
            ),
          );
        } catch (e) {
          print('Error inserting subtopic: $subtopic');
          print('Error details: $e');
          rethrow;
        }
      }

      // Insert questions
      for (final question in questions) {
        try {
          // Skip questions without a valid subtopic_id
          final subtopicId = question['subtopic_id'] as int?;
          if (subtopicId == null) {
            print('⚠️ Skipping question ${question['id']}: missing subtopic_id');
            continue;
          }
          
          await _db.upsertQuestion(
            LocalQuestionsCompanion(
              id: drift.Value(question['id'] as int),
              subtopicId: drift.Value(subtopicId),
              textIt: drift.Value(question['text_it'] as String? ?? ''),
              textEn: drift.Value(question['text_en'] as String? ?? ''),
              textBn: drift.Value(question['text_bn'] as String? ?? ''),
              imageUrl: drift.Value(question['image_url'] as String?),
              isTrue: drift.Value(question['is_true'] as bool? ?? false),
              explanationIt: drift.Value(question['explanation_it'] as String?),
            ),
          );
        } catch (e) {
          print('Error inserting question: $question');
          print('Error details: $e');
          rethrow;
        }
      }
    });
  }

  // ====== IMAGE PREFETCHING ======

  /// Extract all unique image URLs from the data
  Set<String> _extractImageUrls(
    List<Map<String, dynamic>> topics,
    List<Map<String, dynamic>> subtopics,
    List<Map<String, dynamic>> questions,
  ) {
    final urls = <String>{};

    // Extract from topics
    for (final topic in topics) {
      final url = topic['image_url'] as String?;
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }

    // Extract from subtopics
    for (final subtopic in subtopics) {
      final url = subtopic['image_url'] as String?;
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }

    // Extract from questions
    for (final question in questions) {
      final url = question['image_url'] as String?;
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Prefetch images with parallel limit of 5
  Stream<ImageDownloadProgress> _prefetchImages(Set<String> imageUrls) async* {
    final totalImages = imageUrls.length;
    var downloadedCount = 0;
    var failedCount = 0;

    yield ImageDownloadProgress(
      progress: 0.0,
      message: 'Starting download of $totalImages images...',
      downloadedCount: 0,
      totalCount: totalImages,
    );

    // Download images in batches of 5
    const batchSize = 5;
    final urlList = imageUrls.toList();

    for (var i = 0; i < urlList.length; i += batchSize) {
      final batch = urlList.skip(i).take(batchSize).toList();
      
      // Download batch in parallel
      await Future.wait(
        batch.map((url) async {
          try {
            await _cacheManager.downloadFile(url);
            downloadedCount++;
          } catch (e) {
            failedCount++;
            // Continue on error - don't fail entire download
          }
        }),
      );

      // Report progress after each batch
      final progress = downloadedCount / totalImages;
      yield ImageDownloadProgress(
        progress: progress,
        message: 'Downloaded $downloadedCount/$totalImages images'
            '${failedCount > 0 ? ' ($failedCount failed)' : ''}',
        downloadedCount: downloadedCount,
        totalCount: totalImages,
        failedCount: failedCount,
      );
    }

    // Final progress
    yield ImageDownloadProgress(
      progress: 1.0,
      message: 'Image download complete: $downloadedCount/$totalImages'
          '${failedCount > 0 ? ' ($failedCount failed)' : ''}',
      downloadedCount: downloadedCount,
      totalCount: totalImages,
      failedCount: failedCount,
    );
  }

  // ====== UTILITY METHODS ======

  /// Check if local database has content
  Future<bool> hasLocalContent() async {
    final count = await _db.getTotalQuestionCount();
    return count > 0;
  }

  /// Get download statistics
  Future<DownloadStats> getDownloadStats() async {
    final categoriesCount = (await _db.getAllCategories()).length;
    final questionsCount = await _db.getTotalQuestionCount();
    
    return DownloadStats(
      categoriesCount: categoriesCount,
      questionsCount: questionsCount,
      lastUpdated: DateTime.now(), // TODO: Store actual timestamp
    );
  }

  /// Clear all local content
  Future<void> clearLocalContent() async {
    await _db.clearAllData();
    await _cacheManager.emptyCache();
    
    // Mark content as not downloaded
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_contentDownloadedKey, false);
    await prefs.setString(_downloadStateKey, DownloadState.notStarted.value);
    await prefs.remove(_downloadErrorKey);
  }
  
  // ====== DOWNLOAD STATE HELPERS ======
  
  /// Get current download state
  static Future<DownloadState> getDownloadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_downloadStateKey);
    if (stateString == null) {
      // Check legacy key for backward compatibility
      final isDownloaded = prefs.getBool(_contentDownloadedKey) ?? false;
      return isDownloaded ? DownloadState.completed : DownloadState.notStarted;
    }
    return DownloadState.fromString(stateString);
  }
  
  /// Get last download error message if any
  static Future<String?> getLastError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadErrorKey);
  }
  
  /// Get last successful download timestamp
  static Future<DateTime?> getLastDownloadTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_downloadTimestampKey);
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear download state (for testing/reset)
  static Future<void> clearDownloadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadStateKey);
    await prefs.remove(_contentDownloadedKey);
    await prefs.remove(_downloadErrorKey);
    await prefs.remove(_downloadTimestampKey);
  }
  
  /// Check if content is available for offline use
  static Future<bool> isContentAvailable() async {
    final state = await getDownloadState();
    return state.isAvailableOffline;
  }
  
  // ====== CACHE VERSION METHODS ======
  
  /// Check if local cache needs update (stale data)
  Future<CacheUpdateCheck> checkForUpdates() async {
    return await _versionManager.checkForUpdates();
  }
  
  /// Check if we should check for updates (rate-limited to once per hour)
  Future<bool> shouldCheckForUpdates() async {
    return await _versionManager.shouldCheckForUpdates();
  }
  
  /// Get cache age in days
  Future<int> getCacheAge() async {
    return await _versionManager.getCacheAgeDays();
  }
  
  /// Get local cache version
  Future<int> getLocalVersion() async {
    return await _versionManager.getLocalVersion();
  }
}

// ====== PROGRESS MODELS ======

enum DownloadStage {
  fetchingData,
  savingToDatabase,
  downloadingImages,
  completed,
  error,
}

class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final DownloadStage stage;
  final String message;
  final Object? error;

  DownloadProgress({
    required this.progress,
    required this.stage,
    required this.message,
    this.error,
  });

  bool get isComplete => stage == DownloadStage.completed;
  bool get hasError => stage == DownloadStage.error;
}

class ImageDownloadProgress {
  final double progress; // 0.0 to 1.0
  final String message;
  final int downloadedCount;
  final int totalCount;
  final int failedCount;

  ImageDownloadProgress({
    required this.progress,
    required this.message,
    required this.downloadedCount,
    required this.totalCount,
    this.failedCount = 0,
  });
}

class DownloadStats {
  final int categoriesCount;
  final int questionsCount;
  final DateTime lastUpdated;

  DownloadStats({
    required this.categoriesCount,
    required this.questionsCount,
    required this.lastUpdated,
  });
}
