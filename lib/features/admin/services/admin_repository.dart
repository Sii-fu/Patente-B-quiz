import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/profile.dart';

/// Repository for all admin-related database operations
class AdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _theoryImagesBucket = 'theory-images';
  static const String _videoThumbnailsBucket = 'video-thumbnails';

  // ==================== AUTH & PROFILE ====================

  /// Verify admin PIN against stored username
  Future<bool> verifyAdminPin(String pin) async {
    try {
      final response = await _supabase.rpc(
        'verify_admin_pin',
        params: {'input_pin': pin},
      );
      return response as bool? ?? false;
    } catch (e) {
      debugPrint('Error verifying admin PIN: $e');
      return false;
    }
  }

  /// Get current user's profile
  Future<Profile?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .rpc('func_get_all_users_for_admin')
          .timeout(const Duration(seconds: 15));
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  /// Update user verification status (admin only)
  Future<bool> updateUserVerification(String userId, bool isVerified) async {
    try {
      await _supabase.rpc(
        'func_admin_verify_user',
        params: {'target_user_id': userId, 'verify_status': isVerified},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user verification: $e');
      return false;
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  /// Create or update a category
  Future<bool> upsertCategory({
    int? id,
    required String nameIt,
    String? nameEn,
    String? nameBn,
    String? colorHex,
    int? displayOrder,
  }) async {
    try {
      final data = {
        'name_it': nameIt,
        'name_en': nameEn,
        'name_bn': nameBn,
        'color_hex': colorHex,
        'display_order': displayOrder ?? 0,
      };

      if (id != null) {
        await _supabase.from('categories').update(data).eq('id', id);
      } else {
        await _supabase.from('categories').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error upserting category: $e');
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(int id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  // ==================== TOPICS ====================

  /// Get all topics
  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, categories(*)')
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching topics: $e');
      return [];
    }
  }

  /// Get topics by category ID
  Future<List<Map<String, dynamic>>> getTopicsByCategory(int categoryId) async {
    try {
      final response = await _supabase
          .from('topics')
          .select()
          .eq('category_id', categoryId)
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching topics by category: $e');
      return [];
    }
  }

  /// Create or update a topic
  Future<bool> upsertTopic({
    int? id,
    required int categoryId,
    required String nameIt,
    String? nameEn,
    String? nameBn,
    String? imageUrl,
    int? displayOrder,
  }) async {
    try {
      final data = {
        'category_id': categoryId,
        'name_it': nameIt,
        'name_en': nameEn,
        'name_bn': nameBn,
        'image_url': imageUrl,
        'display_order': displayOrder ?? 0,
      };

      if (id != null) {
        await _supabase.from('topics').update(data).eq('id', id);
      } else {
        await _supabase.from('topics').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error upserting topic: $e');
      return false;
    }
  }

  /// Delete a topic
  Future<bool> deleteTopic(int id) async {
    try {
      await _supabase.from('topics').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting topic: $e');
      return false;
    }
  }

  // ==================== SUBTOPICS ====================

  /// Get all subtopics
  Future<List<Map<String, dynamic>>> getSubtopics() async {
    try {
      final response = await _supabase
          .from('subtopics')
          .select('*, topics(*)')
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching subtopics: $e');
      return [];
    }
  }

  /// Get subtopics by topic ID
  Future<List<Map<String, dynamic>>> getSubtopicsByTopic(int topicId) async {
    try {
      final response = await _supabase
          .from('subtopics')
          .select()
          .eq('topic_id', topicId)
          .order('display_order', ascending: true)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching subtopics by topic: $e');
      return [];
    }
  }

  /// Get a single subtopic by its id
  Future<Map<String, dynamic>?> getSubtopicById(int subtopicId) async {
    try {
      final response = await _supabase
          .from('subtopics')
          .select('id, topic_id, name_it, display_order')
          .eq('id', subtopicId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching subtopic by id: $e');
      return null;
    }
  }

  /// Create or update a subtopic
  Future<bool> upsertSubtopic({
    int? id,
    required int topicId,
    required String nameIt,
    String? nameEn,
    String? nameBn,
    String? imageUrl,
    int? displayOrder,
  }) async {
    try {
      final data = {
        'topic_id': topicId,
        'name_it': nameIt,
        'name_en': nameEn,
        'name_bn': nameBn,
        'image_url': imageUrl,
        'display_order': displayOrder ?? 0,
      };

      if (id != null) {
        await _supabase.from('subtopics').update(data).eq('id', id);
      } else {
        await _supabase.from('subtopics').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error upserting subtopic: $e');
      return false;
    }
  }

  /// Delete a subtopic
  Future<bool> deleteSubtopic(int id) async {
    try {
      await _supabase.from('subtopics').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting subtopic: $e');
      return false;
    }
  }

  // ==================== QUESTIONS ====================

  /// Get all questions with filters
  Future<List<Map<String, dynamic>>> getQuestions({
    int? subtopicId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('questions').select('''
        *,
        subtopics!inner(
          id,
          name_it,
          name_en,
          name_bn,
          topics!inner(
            id,
            name_it,
            name_en,
            name_bn
          )
        )
      ''');

      if (subtopicId != null) {
        query = query.eq('subtopic_id', subtopicId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'text_it.ilike.%$searchQuery%,text_en.ilike.%$searchQuery%',
        );
      }

      final response = await query
          .order('id', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 15));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      return [];
    }
  }

  /// Get questions by subtopic ID
  Future<List<Map<String, dynamic>>> getQuestionsBySubtopic(
    int subtopicId,
  ) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('subtopic_id', subtopicId)
          .order('id')
          .timeout(const Duration(seconds: 15));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching questions by subtopic: $e');
      return [];
    }
  }

  /// Get question count by subtopic
  Future<int> getQuestionCountBySubtopic(int subtopicId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('id')
          .eq('subtopic_id', subtopicId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error getting question count: $e');
      return 0;
    }
  }

  // ==================== AUDIO & QUESTIONS (upsert) ====================

  /// Upload a local audio file to the [quiz_audio] Supabase Storage bucket.
  /// Returns the public URL on success, or null on failure.
  ///
  /// Note: Requires RLS policy on quiz_audio bucket:
  /// - Allow authenticated users to INSERT
  /// - Path prefix: /questions/
  Future<String?> uploadAudio(String localFilePath) async {
    try {
      final file = File(localFilePath);
      final bytes = await file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get current user ID for file organization
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('Error uploading audio: User not authenticated');
        return null;
      }

      // Organize files by user and timestamp: questions/admin_user_id/timestamp.m4a
      final fileName = 'questions/${user.id}/$timestamp.m4a';

      await _supabase.storage
          .from('quiz_audio')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
          );

      return _supabase.storage.from('quiz_audio').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  /// Upsert a question (admin only).
  /// If [explanationAudioUrl] is provided, it is written to the
  /// `explanation_audio_url` column via a secondary direct update after
  /// the main RPC completes.
  Future<int?> upsertQuestion({
    int? id,
    required int subtopicId,
    required String textIt,
    String? textEn,
    String? textBn,
    String? imageUrl,
    required bool isTrue,
    String? explanationIt,
    String? explanationEn,
    String? explanationBn,
    String? explanationAudioUrl,
    String? audioItUrl,
    String? audioEnUrl,
    String? audioBnUrl,
    int difficultyLevel = 1,
  }) async {
    try {
      final response = await _supabase.rpc(
        'func_admin_upsert_question',
        params: {
          'p_id': id,
          'p_subtopic_id': subtopicId,
          'p_text_it': textIt,
          'p_text_en': textEn,
          'p_text_bn': textBn,
          'p_image_url': imageUrl,
          'p_is_true': isTrue,
          'p_explanation_it': explanationIt,
          'p_explanation_en': explanationEn,
          'p_explanation_bn': explanationBn,
          'p_audio_it_url': audioItUrl,
          'p_audio_en_url': audioEnUrl,
          'p_audio_bn_url': audioBnUrl,
          'p_difficulty_level': difficultyLevel,
        },
      );

      final questionId = response as int?;

      // Secondary update for explanation_audio_url (not in the RPC).
      if (explanationAudioUrl != null && questionId != null) {
        await _supabase
            .from('questions')
            .update({'explanation_audio_url': explanationAudioUrl})
            .eq('id', questionId);
      }

      return questionId;
    } catch (e) {
      debugPrint('Error upserting question: $e');
      return null;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(int id) async {
    try {
      await _supabase.from('questions').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return false;
    }
  }

  // ==================== THEORY CHAPTERS ====================

  /// Get all theory chapters
  Future<List<Map<String, dynamic>>> getTheoryChapters() async {
    try {
      final response = await _supabase
          .from('theory_chapters')
          .select()
          .order('display_order', ascending: true)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching theory chapters: $e');
      return [];
    }
  }

  /// Get subtopics linked to a theory chapter via its related_quiz_topic_id
  Future<List<Map<String, dynamic>>> getSubtopicsByTheoryChapter(
    int chapterId,
  ) async {
    try {
      final chapter = await _supabase
          .from('theory_chapters')
          .select('related_quiz_topic_id')
          .eq('id', chapterId)
          .single();

      final topicId = chapter['related_quiz_topic_id'] as int?;
      if (topicId == null) return [];

      return getSubtopicsByTopic(topicId);
    } catch (e) {
      debugPrint('Error fetching subtopics by theory chapter: $e');
      return [];
    }
  }

  /// Find the theory card (and therefore its chapter_id) linked to a
  /// given subtopic id, used to reverse-resolve a chapter from a subtopic.
  Future<Map<String, dynamic>?> getTheoryCardBySubtopicId(
    int subtopicId,
  ) async {
    try {
      final response = await _supabase
          .from('theory_cards')
          .select('id, chapter_id, subtopic_id')
          .eq('subtopic_id', subtopicId)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching theory card by subtopic id: $e');
      return null;
    }
  }

  /// Create or update a theory chapter
  Future<bool> upsertTheoryChapter({
    int? id,
    required String nameIt,
    String? nameEn,
    String? nameBn,
    String? imageUrl,
    int? displayOrder,
    int? relatedQuizTopicId,
  }) async {
    try {
      final data = {
        'name_it': nameIt,
        'name_en': nameEn,
        'name_bn': nameBn,
        'image_url': imageUrl,
        'display_order': displayOrder ?? 0,
        'related_quiz_topic_id': relatedQuizTopicId,
      };

      if (id != null) {
        await _supabase.from('theory_chapters').update(data).eq('id', id);
      } else {
        await _supabase.from('theory_chapters').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error upserting theory chapter: $e');
      return false;
    }
  }

  /// Delete a theory chapter
  Future<bool> deleteTheoryChapter(int id) async {
    try {
      await _supabase.from('theory_chapters').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting theory chapter: $e');
      return false;
    }
  }

  // ==================== THEORY CARDS ====================

  /// Get all theory cards with filters
  Future<List<Map<String, dynamic>>> getTheoryCards({
    int? chapterId,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from('theory_cards').select('''
        *,
        theory_chapters!inner(
          id,
          name_it,
          name_en,
          name_bn
        )
      ''');

      if (chapterId != null) {
        query = query.eq('chapter_id', chapterId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title_it.ilike.%$searchQuery%,text_it.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching theory cards: $e');
      return [];
    }
  }

  /// Get theory cards by chapter ID
  Future<List<Map<String, dynamic>>> getTheoryCardsByChapter(
    int chapterId,
  ) async {
    try {
      final response = await _supabase
          .from('theory_cards')
          .select()
          .eq('chapter_id', chapterId)
          .order('display_order', ascending: true)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching theory cards by chapter: $e');
      return [];
    }
  }

  /// Get theory card count by chapter
  Future<int> getTheoryCardCountByChapter(int chapterId) async {
    try {
      final response = await _supabase
          .from('theory_cards')
          .select('id')
          .eq('chapter_id', chapterId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error getting theory card count: $e');
      return 0;
    }
  }

  /// Get question/quiz count by chapter/category
  Future<int> getQuestionCountByChapter(int chapterId) async {
    try {
      // 1. Get unique subtopic IDs for this chapter from theory_cards
      final theoryCardsResponse = await _supabase
          .from('theory_cards')
          .select('subtopic_id')
          .eq('chapter_id', chapterId)
          .not('subtopic_id', 'is', null);

      final Set<int> subtopicIds = {};
      for (var card in theoryCardsResponse as List) {
        if (card['subtopic_id'] != null) {
          subtopicIds.add(card['subtopic_id'] as int);
        }
      }

      if (subtopicIds.isEmpty) return 0;

      // 2. Count questions in these subtopics
      final response = await _supabase
          .from('questions')
          .select('id')
          .inFilter('subtopic_id', subtopicIds.toList())
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error getting question count by chapter: $e');
      return 0;
    }
  }

  /// Upsert a theory card (admin only)
  Future<bool> upsertTheoryCard({
    int? id,
    required int chapterId,
    String? titleIt,
    String? titleEn,
    String? titleBn,
    required String textIt,
    String? textEn,
    String? textBn,
    String? imageUrl,
    int displayOrder = 1,
  }) async {
    try {
      await _supabase.rpc(
        'func_admin_upsert_theory_card',
        params: {
          'p_id': id,
          'p_chapter_id': chapterId,
          'p_title_it': titleIt,
          'p_title_en': titleEn,
          'p_title_bn': titleBn,
          'p_text_it': textIt,
          'p_text_en': textEn,
          'p_text_bn': textBn,
          'p_image_url': imageUrl,
          'p_display_order': displayOrder,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error upserting theory card: $e');
      return false;
    }
  }

  /// Delete a theory card
  Future<bool> deleteTheoryCard(int id) async {
    try {
      await _supabase.from('theory_cards').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting theory card: $e');
      return false;
    }
  }

  // ==================== VIDEO CATEGORIES ====================

  /// Get all video categories
  Future<List<Map<String, dynamic>>> getVideoCategories() async {
    try {
      final response = await _supabase
          .from('video_categories')
          .select()
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching video categories: $e');
      return [];
    }
  }

  /// Create or update a video category
  Future<bool> upsertVideoCategory({
    int? id,
    required String nameIt,
    String? nameEn,
    String? nameBn,
    int? displayOrder,
  }) async {
    try {
      final data = {
        'name_it': nameIt,
        'name_en': nameEn,
        'name_bn': nameBn,
        'display_order': displayOrder ?? 0,
      };

      if (id != null) {
        await _supabase.from('video_categories').update(data).eq('id', id);
      } else {
        await _supabase.from('video_categories').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error upserting video category: $e');
      return false;
    }
  }

  /// Delete a video category
  Future<bool> deleteVideoCategory(int id) async {
    try {
      await _supabase.from('video_categories').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting video category: $e');
      return false;
    }
  }

  // ==================== VIDEOS ====================

  /// Get all videos
  Future<List<Map<String, dynamic>>> getVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      return [];
    }
  }

  /// Get all videos joined with their theory chapter (for the unified admin
  /// management screen). Fetches both the [videos] and [theory_chapters] tables
  /// and stitches them together client-side, attaching the matching chapter map
  /// under each video's `chapter` key (or `null` for live classes / unmatched).
  ///
  /// A client-side join is used instead of a PostgREST embed so this does not
  /// depend on a declared foreign-key relationship between the two tables, and
  /// so a missing chapter never drops the video from the result set.
  ///
  /// Sorted newest-first by `class_date` (falling back to `created_at`), which
  /// is the default order the management screen presents before any local
  /// re-sorting is applied.
  ///
  /// Each video is also tagged with a 1-based `chapter_number` derived from the
  /// chapter's rank in the `id`-ordered chapter list (chapter 1 → 25). This is
  /// used instead of `display_order`, which is nullable/unset in the data and
  /// would otherwise render every tag as "CHAPTER 0".
  Future<List<Map<String, dynamic>>> getVideosWithChapters() async {
    try {
      final videosResponse = await _supabase
          .from('videos')
          .select()
          .timeout(const Duration(seconds: 10));
      final chaptersResponse = await _supabase
          .from('theory_chapters')
          .select('id, name_it, name_en, name_bn, display_order')
          .timeout(const Duration(seconds: 10));

      final videos = List<Map<String, dynamic>>.from(videosResponse as List);
      final chapters = List<Map<String, dynamic>>.from(
        chaptersResponse as List,
      );

      int chapterIdOf(Map<String, dynamic> chapter) {
        final id = chapter['id'];
        if (id is int) return id;
        if (id is num) return id.toInt();
        return int.tryParse('${id ?? ''}') ?? 0;
      }

      // Rank chapters by id (ascending) → 1-based chapter number.
      chapters.sort((a, b) => chapterIdOf(a).compareTo(chapterIdOf(b)));
      final chapterNumberById = <dynamic, int>{};
      for (var i = 0; i < chapters.length; i++) {
        chapterNumberById[chapters[i]['id']] = i + 1;
      }

      final chapterById = <dynamic, Map<String, dynamic>>{
        for (final chapter in chapters) chapter['id']: chapter,
      };

      for (final video in videos) {
        final chapterId = video['chapter_id'];
        video['chapter'] = chapterId != null ? chapterById[chapterId] : null;
        video['chapter_number'] = chapterId != null
            ? chapterNumberById[chapterId]
            : null;
      }

      int dateMillis(Map<String, dynamic> video) {
        final raw = video['class_date'] ?? video['created_at'];
        if (raw is String) {
          return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
        }
        if (raw is DateTime) return raw.millisecondsSinceEpoch;
        return 0;
      }

      videos.sort((a, b) => dateMillis(b).compareTo(dateMillis(a)));
      return videos;
    } catch (e) {
      debugPrint('Error fetching videos with chapters: $e');
      return [];
    }
  }

  /// Get videos by category ID
  Future<List<Map<String, dynamic>>> getVideosByCategory(int categoryId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('category_id', categoryId)
          .order('display_order')
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching videos by category: $e');
      return [];
    }
  }

  /// Get video count by category
  Future<int> getVideoCountByCategory(int categoryId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select('id')
          .eq('category_id', categoryId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error getting video count: $e');
      return 0;
    }
  }

  /// Create or update a video
  Future<bool> upsertVideo({
    int? id,
    int? categoryId,
    int? chapterId,
    required String titleIt,
    String? titleEn,
    String? titleBn,
    required String youtubeUrl,
    int? durationMinutes,
    String? thumbnailUrl,
    int? displayOrder,
    required bool isLiveClass,
    required DateTime classDate,
  }) async {
    try {
      await _supabase.rpc(
        'admin_upsert_video_secure',
        params: {
          'p_id': id,
          'p_category_id': categoryId,
          'p_chapter_id': chapterId,
          'p_title_it': titleIt,
          'p_title_en': titleEn,
          'p_title_bn': titleBn,
          'p_youtube_url': youtubeUrl,
          'p_duration_minutes': durationMinutes,
          'p_thumbnail_url': thumbnailUrl,
          'p_display_order': displayOrder ?? 0,
          'p_is_live_class': isLiveClass,
          'p_class_date': classDate.toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error upserting video: $e');
      return false;
    }
  }

  /// Upload video thumbnail image to the dedicated [video-thumbnails] bucket.
  /// Returns the public URL on success, or null on failure.
  Future<String?> uploadVideoThumbnail(
    List<int> bytes, {
    String? originalFileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Error uploading video thumbnail: User not authenticated');
      return null;
    }

    final rawName = (originalFileName ?? '').trim();
    final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)$').firstMatch(rawName);
    final extension = extensionMatch != null
        ? extensionMatch.group(1)!.toLowerCase()
        : (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(rawName)
              ? rawName.toLowerCase()
              : 'jpg');

    final fileName = 'videos/${user.id}/$timestamp.$extension';
    return uploadImage(_videoThumbnailsBucket, fileName, bytes);
  }

  /// Delete a video
  Future<bool> deleteVideo(int id) async {
    try {
      await _supabase.from('videos').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting video: $e');
      return false;
    }
  }

  /// Delete a file from a Supabase Storage bucket by its object path.
  Future<bool> deleteStorageFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      debugPrint('Error deleting storage file: $e');
      return false;
    }
  }

  // ==================== UTILITIES ====================

  /// Upload image to Supabase Storage
  Future<String?> uploadImage(
    String bucket,
    String fileName,
    List<int> bytes,
  ) async {
    final user = _supabase.auth.currentUser;
    debugPrint(
      'uploadImage called: bucket=$bucket file=$fileName user=${user?.id} bytes=${bytes.length}',
    );
    if (user == null) {
      debugPrint('Error uploading image: User not authenticated');
      return null;
    }

    try {
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            bytes as dynamic,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fileName);
      debugPrint('uploadImage success: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      debugPrint('Error uploading image: $e\n$st');
      return null;
    }
  }

  /// Upload theory card image to the dedicated [theory-images] bucket.
  /// Returns the public URL on success, or null on failure.
  Future<String?> uploadTheoryCardImage(
    List<int> bytes, {
    String? originalFileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Error uploading theory image: User not authenticated');
      return null;
    }

    final rawName = (originalFileName ?? '').trim();
    final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)$').firstMatch(rawName);
    final extension = extensionMatch != null
        ? extensionMatch.group(1)!.toLowerCase()
        : (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(rawName)
              ? rawName.toLowerCase()
              : 'jpg');
    final fileName = 'theory_cards/${user.id}/$timestamp.$extension';
    return uploadImage(_theoryImagesBucket, fileName, bytes);
  }

  /// Upload audio to Supabase Storage
  Future<String?> uploadAudioBinary(
    String bucket,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            bytes as dynamic,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  /// Update question's audio URL using secure RPC function
  Future<bool> updateQuestionAudioUrl({
    required int questionId,
    required String audioUrl,
  }) async {
    try {
      debugPrint(
        '🎙️ Calling RPC: update_question_audio($questionId, $audioUrl)',
      );

      final result = await _supabase.rpc(
        'update_question_audio',
        params: {'p_question_id': questionId, 'p_audio_url': audioUrl},
      );

      debugPrint('✅ RPC response: $result');
      return result == true;
    } catch (e) {
      debugPrint('❌ RPC error: $e');
      return false;
    }
  }

  /// Update theory card's audio URL using secure RPC function
  Future<bool> updateTheoryCardAudioUrl({
    required int cardId,
    required String audioUrl,
  }) async {
    try {
      debugPrint(
        '🎙️ Calling RPC: update_theory_card_audio($cardId, $audioUrl)',
      );

      final result = await _supabase.rpc(
        'update_theory_card_audio',
        params: {'p_card_id': cardId, 'p_audio_url': audioUrl},
      );

      debugPrint('✅ RPC response: $result');
      return result == true;
    } catch (e) {
      debugPrint('❌ RPC error: $e');
      return false;
    }
  }
}
