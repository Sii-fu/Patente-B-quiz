import 'package:connectivity_plus/connectivity_plus.dart';
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
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Fetch complete video library with categories and their videos
  /// 
  /// Returns a list of [VideoCategory] objects, each containing their associated videos.
  /// Throws [VideoOfflineException] if no internet connection is available.
  Future<List<VideoCategory>> fetchVideoLibrary() async {
    // Check connectivity first - videos require internet
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      throw VideoOfflineException();
    }

    try {
      // Fetch categories and videos in parallel for better performance
      final results = await Future.wait([
        _fetchCategories(),
        _fetchVideos(),
      ]);

      final categories = results[0] as List<VideoCategory>;
      final videos = results[1] as List<VideoItem>;

      // Group videos by category
      return _groupVideosByCategory(categories, videos);
    } catch (e) {
      if (e is VideoOfflineException) rethrow;
      
      // Handle Supabase errors
      if (e is PostgrestException) {
        throw VideoOfflineException('Failed to load videos: ${e.message}');
      }
      
      throw VideoOfflineException('An error occurred while loading videos');
    }
  }

  /// Fetch all video categories ordered by display_order
  Future<List<VideoCategory>> _fetchCategories() async {
    final response = await _supabase
        .from('video_categories')
        .select()
        .order('display_order', ascending: true);

    final data = List<Map<String, dynamic>>.from(response);
    return data.map((json) => VideoCategory.fromJson(json)).toList();
  }

  /// Fetch all videos ordered by display_order
  Future<List<VideoItem>> _fetchVideos() async {
    final response = await _supabase
        .from('videos')
        .select()
        .order('display_order', ascending: true);

    final data = List<Map<String, dynamic>>.from(response);
    return data.map((json) => VideoItem.fromJson(json)).toList();
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
      videosByCategory.putIfAbsent(video.categoryId, () => []);
      videosByCategory[video.categoryId]!.add(video);
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
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      throw VideoOfflineException();
    }

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
      throw VideoOfflineException('Failed to load videos for this category');
    }
  }

  /// Fetch a single video by ID
  Future<VideoItem?> fetchVideoById(int videoId) async {
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      throw VideoOfflineException();
    }

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
      throw VideoOfflineException('Failed to load video');
    }
  }
}
