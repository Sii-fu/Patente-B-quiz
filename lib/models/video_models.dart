import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Video Category Model
/// Represents a category of videos from the video_categories table
class VideoCategory {
  final int id;
  final String nameIt;
  final String? nameEn;
  final String? nameBn;
  final int displayOrder;
  final DateTime createdAt;
  
  /// List of videos in this category (populated after grouping)
  List<VideoItem> videos;

  VideoCategory({
    required this.id,
    required this.nameIt,
    this.nameEn,
    this.nameBn,
    required this.displayOrder,
    required this.createdAt,
    this.videos = const [],
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'] as int,
      nameIt: json['name_it'] as String,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      videos: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_it': nameIt,
      'name_en': nameEn,
      'name_bn': nameBn,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get localized name based on language code
  /// Falls back to Italian if translation is not available
  String getLocalizedName(String langCode) {
    switch (langCode) {
      case 'en':
        return nameEn ?? nameIt;
      case 'bn':
        return nameBn ?? nameIt;
      default:
        return nameIt;
    }
  }

  /// Create a copy with videos list
  VideoCategory copyWithVideos(List<VideoItem> videos) {
    return VideoCategory(
      id: id,
      nameIt: nameIt,
      nameEn: nameEn,
      nameBn: nameBn,
      displayOrder: displayOrder,
      createdAt: createdAt,
      videos: videos,
    );
  }
}

/// Video Item Model
/// Represents a single video from the videos table
class VideoItem {
  final int id;
  final int? categoryId;
  final String titleIt;
  final String? titleEn;
  final String? titleBn;
  final String youtubeUrl;
  final int? durationMinutes;
  final String? thumbnailUrl;
  final bool isLiveClass;
  final DateTime? classDate;
  final int displayOrder;
  final DateTime createdAt;

  VideoItem({
    required this.id,
    this.categoryId,
    required this.titleIt,
    this.titleEn,
    this.titleBn,
    required this.youtubeUrl,
    this.durationMinutes,
    this.thumbnailUrl,
    this.isLiveClass = false,
    this.classDate,
    required this.displayOrder,
    required this.createdAt,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category_id'];
    final isLiveClassRaw = json['is_live_class'];
    final classDateRaw = json['class_date'];

    final parsedClassDate = classDateRaw is String
        ? DateTime.tryParse(classDateRaw)
        : classDateRaw is DateTime
            ? classDateRaw
            : null;

    return VideoItem(
      id: json['id'] as int,
      categoryId: categoryRaw is int ? categoryRaw : (categoryRaw is num ? categoryRaw.toInt() : null),
      titleIt: json['title_it'] as String,
      titleEn: json['title_en'] as String?,
      titleBn: json['title_bn'] as String?,
      youtubeUrl: json['youtube_url'] as String,
      durationMinutes: json['duration_minutes'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isLiveClass: isLiveClassRaw == true || isLiveClassRaw == 1 || isLiveClassRaw == 'true',
      classDate: parsedClassDate,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title_it': titleIt,
      'title_en': titleEn,
      'title_bn': titleBn,
      'youtube_url': youtubeUrl,
      'duration_minutes': durationMinutes,
      'thumbnail_url': thumbnailUrl,
      'is_live_class': isLiveClass,
      'class_date': classDate?.toIso8601String(),
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get localized title based on language code
  /// Falls back to Italian if translation is not available
  String getLocalizedTitle(String langCode) {
    switch (langCode) {
      case 'en':
        return titleEn ?? titleIt;
      case 'bn':
        return titleBn ?? titleIt;
      default:
        return titleIt;
    }
  }

  /// Extract YouTube video ID from the URL
  /// Uses the YoutubePlayer package for robust URL parsing
  String? get videoId {
    return YoutubePlayer.convertUrlToId(youtubeUrl);
  }

  /// Get YouTube thumbnail URL
  /// Uses the video ID to construct the thumbnail URL
  /// Falls back to custom thumbnail if provided
  String get thumbnailImageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    final id = videoId;
    if (id != null) {
      // High quality thumbnail
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    // Fallback placeholder
    return 'https://via.placeholder.com/320x180?text=Video';
  }

  /// Get formatted duration string (e.g., "5 min")
  String? get formattedDuration {
    if (durationMinutes == null) return null;
    return '$durationMinutes min';
  }
}
