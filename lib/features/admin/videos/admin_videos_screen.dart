import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_video_edit_screen.dart';

/// Admin Videos Screen
/// Directly manages videos (no category selection layer).
class AdminVideosScreen extends StatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _filteredVideos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final videos = await _adminRepository.getVideos();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _filteredVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterVideos(String query) {
    final lower = query.toLowerCase();
    if (lower.isEmpty) {
      setState(() => _filteredVideos = _videos);
      return;
    }

    setState(() {
      _filteredVideos = _videos.where((v) {
        final titleIt = (v['title_it'] ?? '').toString().toLowerCase();
        final titleEn = (v['title_en'] ?? '').toString().toLowerCase();
        final titleBn = (v['title_bn'] ?? '').toString().toLowerCase();
        final youtubeUrl = (v['youtube_url'] ?? '').toString().toLowerCase();
        return titleIt.contains(lower) ||
            titleEn.contains(lower) ||
            titleBn.contains(lower) ||
            youtubeUrl.contains(lower);
      }).toList();
    });
  }

  String _getLocalizedTitle(Map<String, dynamic> item, String langCode) {
    switch (langCode) {
      case 'en':
        return item['title_en'] ?? item['title_it'] ?? '';
      case 'bn':
        return item['title_bn'] ?? item['title_it'] ?? '';
      default:
        return item['title_it'] ?? '';
    }
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String? _getThumbnailUrl(Map<String, dynamic> video) {
    if (video['thumbnail_url'] != null && video['thumbnail_url'].toString().isNotEmpty) {
      return video['thumbnail_url'] as String;
    }
    final youtubeId = _extractYouTubeId(video['youtube_url'] ?? '');
    if (youtubeId != null) {
      return 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';
    }
    return null;
  }

  Future<void> _openVideoEditor([Map<String, dynamic>? video]) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminVideoEditScreen(video: video),
      ),
    );

    if (result == true && mounted) {
      await _loadVideos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminSavedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteVideo),
        content: Text(l10n.adminDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final thumbnailUrl = (video['thumbnail_url'] ?? '').toString();
    if (thumbnailUrl.contains('/storage/v1/object/public/video-thumbnails/')) {
      final path = thumbnailUrl.split('/storage/v1/object/public/video-thumbnails/').last;
      await _adminRepository.deleteStorageFile('video-thumbnails', path);
    }

    final success = await _adminRepository.deleteVideo(video['id'] as int);
    if (!success || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.adminVideoDeleted),
        backgroundColor: Colors.green,
      ),
    );
    await _loadVideos();
  }

  Future<void> _quickReplaceThumbnail(Map<String, dynamic> video) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final uploadedUrl = await _adminRepository.uploadVideoThumbnail(
        bytes,
        originalFileName: picked.name,
      );
      if (uploadedUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        return;
      }

      final oldThumbnail = (video['thumbnail_url'] ?? '').toString();
      final titleEnValue = video['title_en']?.toString();
      final titleBnValue = video['title_bn']?.toString();
      final success = await _adminRepository.upsertVideo(
        id: video['id'] as int,
        categoryId: video['category_id'] as int?,
        titleIt: (video['title_it'] ?? '').toString(),
        titleEn: (titleEnValue == null || titleEnValue.isEmpty) ? null : titleEnValue,
        titleBn: (titleBnValue == null || titleBnValue.isEmpty) ? null : titleBnValue,
        youtubeUrl: (video['youtube_url'] ?? '').toString(),
        durationMinutes: video['duration_minutes'] as int?,
        thumbnailUrl: uploadedUrl,
        displayOrder: video['display_order'] as int? ?? 0,
      );

      if (!success || !mounted) return;

      if (oldThumbnail.contains('/storage/v1/object/public/video-thumbnails/')) {
        final oldPath = oldThumbnail.split('/storage/v1/object/public/video-thumbnails/').last;
        await _adminRepository.deleteStorageFile('video-thumbnails', oldPath);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminSavedSuccessfully), backgroundColor: Colors.green),
      );
      await _loadVideos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminVideos),
        backgroundColor: theme.colorScheme.surfaceTint,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVideoEditor(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddVideo),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.adminSearchVideos,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterVideos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: _filterVideos,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredVideos.length} ${l10n.adminVideos}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadVideos,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : _filteredVideos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.adminNoVideos,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadVideos,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                              itemCount: _filteredVideos.length,
                              itemBuilder: (context, index) {
                                final video = _filteredVideos[index];
                                final title = _getLocalizedTitle(video, langCode);
                                final thumbnailUrl = _getThumbnailUrl(video);
                                final duration = video['duration_minutes'];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _openVideoEditor(video),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Stack(
                                            children: [
                                              thumbnailUrl != null
                                                  ? Image.network(
                                                      thumbnailUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.play_circle_outline,
                                                          size: 48,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.play_circle_outline,
                                                          size: 48,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                              if (duration != null)
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '$duration min',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              const Center(
                                                child: Icon(
                                                  Icons.play_circle_fill,
                                                  size: 48,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style: theme.textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '#${video['display_order'] ?? index + 1}',
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.image_outlined, size: 20),
                                                onPressed: () => _quickReplaceThumbnail(video),
                                                tooltip: l10n.adminThumbnailUrl,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 20),
                                                onPressed: () => _openVideoEditor(video),
                                                tooltip: l10n.adminEdit,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                                onPressed: () => _deleteVideo(video),
                                                tooltip: l10n.adminDelete,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
