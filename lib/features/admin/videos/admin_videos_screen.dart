import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';

/// Admin Videos Screen
/// Shows all videos for a category with edit/add/delete functionality
class AdminVideosScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const AdminVideosScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
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
      final videos = await _adminRepository.getVideosByCategory(widget.categoryId);
      if (mounted) {
        setState(() {
          _videos = videos;
          _filteredVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterVideos(String query) {
    if (query.isEmpty) {
      setState(() => _filteredVideos = _videos);
    } else {
      setState(() {
        _filteredVideos = _videos.where((v) {
          final titleIt = (v['title_it'] ?? '').toString().toLowerCase();
          final titleEn = (v['title_en'] ?? '').toString().toLowerCase();
          return titleIt.contains(query.toLowerCase()) ||
                 titleEn.contains(query.toLowerCase());
        }).toList();
      });
    }
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
    // Handle various YouTube URL formats
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String? _getThumbnailUrl(Map<String, dynamic> video) {
    if (video['thumbnail_url'] != null && video['thumbnail_url'].toString().isNotEmpty) {
      return video['thumbnail_url'];
    }
    // Generate YouTube thumbnail from video URL
    final youtubeId = _extractYouTubeId(video['youtube_url'] ?? '');
    if (youtubeId != null) {
      return 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';
    }
    return null;
  }

  Future<void> _showVideoDialog([Map<String, dynamic>? video]) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = video != null;
    
    final titleItController = TextEditingController(text: video?['title_it'] ?? '');
    final titleEnController = TextEditingController(text: video?['title_en'] ?? '');
    final titleBnController = TextEditingController(text: video?['title_bn'] ?? '');
    final youtubeUrlController = TextEditingController(text: video?['youtube_url'] ?? '');
    final durationController = TextEditingController(
      text: (video?['duration_minutes'] ?? '').toString().replaceAll('null', '')
    );
    final thumbnailController = TextEditingController(text: video?['thumbnail_url'] ?? '');
    final displayOrderController = TextEditingController(
      text: (video?['display_order'] ?? 0).toString()
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.adminEditVideo : l10n.adminAddVideo),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleItController,
                  decoration: InputDecoration(
                    labelText: '${l10n.adminTitleIt} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleEnController,
                  decoration: InputDecoration(
                    labelText: l10n.adminTitleEn,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleBnController,
                  decoration: InputDecoration(
                    labelText: l10n.adminTitleBn,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: youtubeUrlController,
                  decoration: InputDecoration(
                    labelText: '${l10n.adminYoutubeUrl} *',
                    border: const OutlineInputBorder(),
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: l10n.adminDurationMinutes,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: displayOrderController,
                        decoration: InputDecoration(
                          labelText: l10n.adminDisplayOrder,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnailController,
                  decoration: InputDecoration(
                    labelText: l10n.adminThumbnailUrl,
                    border: const OutlineInputBorder(),
                    helperText: l10n.adminThumbnailHelper,
                    helperMaxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleItController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.adminTitleRequired),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              if (youtubeUrlController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.adminYoutubeUrlRequired),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              final success = await _adminRepository.upsertVideo(
                id: video?['id'],
                categoryId: widget.categoryId,
                titleIt: titleItController.text.trim(),
                titleEn: titleEnController.text.trim().isEmpty ? null : titleEnController.text.trim(),
                titleBn: titleBnController.text.trim().isEmpty ? null : titleBnController.text.trim(),
                youtubeUrl: youtubeUrlController.text.trim(),
                durationMinutes: int.tryParse(durationController.text),
                thumbnailUrl: thumbnailController.text.trim().isEmpty ? null : thumbnailController.text.trim(),
                displayOrder: int.tryParse(displayOrderController.text) ?? 0,
              );

              if (success && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.settingsSave),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadVideos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
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

    if (confirmed == true) {
      final success = await _adminRepository.deleteVideo(video['id'] as int);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminVideoDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _loadVideos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.purple.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVideoDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddVideo),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Search Bar
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
          
          // Stats
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
          
          // Videos List
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
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 100,
                              ),
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
                                    onTap: () => _showVideoDialog(video),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Thumbnail
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
                                              // Duration badge
                                              if (duration != null)
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '$duration min',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Play icon overlay
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
                                        
                                        // Video Info
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
                                                icon: const Icon(Icons.edit, size: 20),
                                                onPressed: () => _showVideoDialog(video),
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
