import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../utils/constants.dart';

/// Reusable image widget for quiz questions with smart URL handling and caching
/// 
/// Automatically:
/// - Constructs full Supabase Storage URL from filename
/// - Uses CachedNetworkImage for offline support
/// - Provides loading and error states
class QuizImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const QuizImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  /// Transforms image URL - if it's just a filename, construct full Supabase Storage URL
  String _getFullImageUrl() {
    // If already a full URL (starts with http/https), use it directly
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Otherwise, construct Supabase Storage URL
    // Format: https://[project_id].supabase.co/storage/v1/object/public/[bucket]/[filename]
    final supabaseUrl = AppConstants.supabaseUrl;
    const storageBucket = 'question-images'; // Default bucket name
    
    return '$supabaseUrl/storage/v1/object/public/$storageBucket/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = _getFullImageUrl();

    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: fit,
      width: width,
      height: height,
      cacheManager: DefaultCacheManager(),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
