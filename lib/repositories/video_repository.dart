import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_models.dart';

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

  /// Fetch complete video library with categories and their videos
  /// 
  /// Returns a list of [VideoCategory] objects, each containing their associated videos.
  /// Throws [VideoOfflineException] if no internet connection is available.
  Future<List<VideoCategory>> fetchVideoLibrary() async {
    debugPrint('🎬 fetchVideoLibrary() started');
    try {
      // Fetch categories and videos in parallel for better performance
      final results = await Future.wait([
        _fetchCategories(),
        _fetchVideos(),
      ]);

      final categories = results[0] as List<VideoCategory>;
      final videos = results[1] as List<VideoItem>;
      debugPrint('✅ fetchVideoLibrary() fetched categories=${categories.length}, videos=${videos.length}');

      // Group videos by category
      return _groupVideosByCategory(categories, videos);
    } catch (e) {
      debugPrint('❌ fetchVideoLibrary() error type=${e.runtimeType} error=$e');
      if (e is VideoOfflineException) rethrow;
      
      if (e is PostgrestException) {
        debugPrint(
          '❌ Supabase PostgrestException in fetchVideoLibrary(): code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}',
        );
        throw Exception('Failed to load videos: ${e.message}');
      }

      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        debugPrint('❌ fetchVideoLibrary() mapped to VideoOfflineException');
        throw VideoOfflineException();
      }

      throw Exception('An error occurred while loading videos');
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

  /// Fetch all videos ordered by display_order
  Future<List<VideoItem>> _fetchVideos() async {
    debugPrint('🎞️ _fetchVideos() querying videos');
    final response = await _supabase
        .from('videos')
        .select()
        .order('display_order', ascending: true);

    final data = List<Map<String, dynamic>>.from(response);
    debugPrint('✅ _fetchVideos() rows=${data.length}');
    return data.map((json) => VideoItem.fromJson(json)).toList();
  }

  /// Fetch all videos as a flat list (no category grouping).
  Future<List<VideoItem>> fetchAllVideos() async {
    debugPrint('🎬 fetchAllVideos() started');
    try {
      final videos = await _fetchVideos();
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
