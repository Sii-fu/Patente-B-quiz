import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_models.dart';
import '../models/theory_chapter.dart';

/// Exception thrown when video content cannot be loaded due to network issues
class VideoOfflineException implements Exception {
  final String message;
  VideoOfflineException([this.message = 'Video content requires an internet connection']);
  
  @override
  String toString() => message;
}

/// Repository for fetching video content from Supabase
/// Videos require internet connection and cannot be cached offline
class VideoRepository {
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  VideoRepository({
    SupabaseClient? supabaseClient,
    Connectivity? connectivity,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _connectivity = connectivity ?? Connectivity();

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      debugPrint('📡 VideoRepository connectivity result: $result');
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ VideoRepository connectivity check error: $e');
      return false;
    }
  }

  /// Fetch normal (non-live) videos grouped by category.
  /// Returns a list of [VideoCategory] objects with populated videos.
  Future<List<VideoCategory>> fetchNormalVideos() async {
    debugPrint('🎬 fetchNormalVideos() started');
    try {
      final results = await Future.wait([
        _fetchCategories(),
        _fetchNormalVideosData(),
      ]);

      final categories = results[0] as List<VideoCategory>;
      final videos = results[1] as List<VideoItem>;
      debugPrint('✅ fetchNormalVideos() fetched categories=${categories.length}, videos=${videos.length}');

      return _groupVideosByCategory(categories, videos);
    } catch (e) {
      debugPrint('❌ fetchNormalVideos() error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      
      if (e is PostgrestException) {
        debugPrint(
          '❌ Supabase PostgrestException in fetchNormalVideos(): code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}',
        );
        throw Exception('Failed to load videos: ${e.message}');
      }

      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        debugPrint('❌ fetchNormalVideos() mapped to VideoOfflineException');
        throw VideoOfflineException();
      }

      throw Exception('An error occurred while loading videos');
    }
  }

  /// Backward-compatible alias for category-grouped normal videos.
  Future<List<VideoCategory>> fetchVideoLibrary() => fetchNormalVideos();

  /// Fetch live classes ordered by class_date DESC (newest first).
  Future<List<VideoItem>> fetchLiveClasses() async {
    debugPrint('🎬 fetchLiveClasses() started');
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('is_live_class', true)
          .order('class_date', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('✅ fetchLiveClasses() rows=${data.length}');
      return data.map((json) => VideoItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ fetchLiveClasses() error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        throw Exception('Failed to load live classes: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        throw VideoOfflineException();
      }
      throw Exception('An error occurred while loading live classes');
    }
  }

  /// Fetch normal (non-live) videos for a specific theory chapter.
  ///
  /// Returns videos where `is_live_class = false` AND `chapter_id = chapterId`,
  /// ordered by display_order (ascending).
  Future<List<VideoItem>> fetchVideosByChapter(int chapterId) async {
    debugPrint('🎬 fetchVideosByChapter($chapterId) started');
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('is_live_class', false)
          .eq('chapter_id', chapterId)
          .order('display_order', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('✅ fetchVideosByChapter($chapterId) rows=${data.length}');
      return data.map((json) => VideoItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ fetchVideosByChapter($chapterId) error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        throw Exception('Failed to load videos for this chapter: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        throw VideoOfflineException();
      }
      throw Exception('An error occurred while loading chapter videos');
    }
  }

  /// Fetch the list of theory chapters (used to display the chapter list in the UI).
  ///
  /// Returns all chapters from the `theory_chapters` table ordered by display_order.
  Future<List<TheoryChapter>> fetchTheoryChapters() async {
    debugPrint('📚 fetchTheoryChapters() started');
    try {
      final response = await _supabase
          .from('theory_chapters')
          .select()
          .order('id', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('✅ fetchTheoryChapters() rows=${data.length}');
      return data.map((json) => TheoryChapter.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ fetchTheoryChapters() error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        throw Exception('Failed to load theory chapters: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        throw VideoOfflineException();
      }
      throw Exception('An error occurred while loading theory chapters');
    }
  }

  /// Fetch all video categories ordered by display_order
  Future<List<VideoCategory>> _fetchCategories() async {
    debugPrint('📂 _fetchCategories() querying video_categories');
    final response = await _supabase
        .from('video_categories')
        .select()
        .order('display_order', ascending: true);

    final data = List<Map<String, dynamic>>.from(response);
    debugPrint('✅ _fetchCategories() rows=${data.length}');
    return data.map((json) => VideoCategory.fromJson(json)).toList();
  }

  /// Fetch normal (non-live) videos ordered by display_order
  Future<List<VideoItem>> _fetchNormalVideosData() async {
    debugPrint('🎞️ _fetchNormalVideosData() querying videos');
    final response = await _supabase
        .from('videos')
        .select()
        .eq('is_live_class', false)
        .order('display_order', ascending: true);

    final data = List<Map<String, dynamic>>.from(response);
    debugPrint('✅ _fetchNormalVideosData() rows=${data.length}');
    return data.map((json) => VideoItem.fromJson(json)).toList();
  }

  /// Fetch all videos as a flat list (no category grouping).
  Future<List<VideoItem>> fetchAllVideos() async {
    debugPrint('🎬 fetchAllVideos() started');
    try {
      final videos = await _fetchNormalVideosData();
      debugPrint('✅ fetchAllVideos() success videos=${videos.length}');
      return videos;
    } catch (e) {
      debugPrint('❌ fetchAllVideos() error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        debugPrint(
          '❌ Supabase PostgrestException in fetchAllVideos(): code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}',
        );
        throw Exception('Failed to load videos: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        debugPrint('❌ fetchAllVideos() mapped to VideoOfflineException');
        throw VideoOfflineException();
      }
      throw Exception('An error occurred while loading videos');
    }
  }

  /// Group videos into their respective categories
  /// Returns categories with their videos list populated
  List<VideoCategory> _groupVideosByCategory(
    List<VideoCategory> categories,
    List<VideoItem> videos,
  ) {
    // Create a map of category ID to videos for O(1) lookup
    final videosByCategory = <int, List<VideoItem>>{};
    
    for (final video in videos) {
      final categoryId = video.categoryId;
      if (categoryId == null) continue;
      videosByCategory.putIfAbsent(categoryId, () => []);
      videosByCategory[categoryId]!.add(video);
    }

    // Assign videos to their categories
    return categories.map((category) {
      final categoryVideos = videosByCategory[category.id] ?? [];
      return category.copyWithVideos(categoryVideos);
    }).where((category) => category.videos.isNotEmpty).toList();
  }

  /// Fetch videos for a specific category
  /// 
  /// Useful for lazy loading or refreshing a single category
  Future<List<VideoItem>> fetchVideosForCategory(int categoryId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('category_id', categoryId)
          .eq('is_live_class', false)
          .order('display_order', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => VideoItem.fromJson(json)).toList();
    } catch (e) {
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        throw Exception('Failed to load videos for this category: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        throw VideoOfflineException();
      }
      throw Exception('Failed to load videos for this category');
    }
  }

  /// Fetch a single video by ID
  Future<VideoItem?> fetchVideoById(int videoId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('id', videoId)
          .maybeSingle();

      if (response == null) return null;
      return VideoItem.fromJson(response);
    } catch (e) {
      if (e is VideoOfflineException) rethrow;
      if (e is PostgrestException) {
        throw Exception('Failed to load video: ${e.message}');
      }
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        throw VideoOfflineException();
      }
      throw Exception('Failed to load video');
    }
  }
}
