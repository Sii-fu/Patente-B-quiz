import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/video_models.dart';
import '../../repositories/video_repository.dart';
import '../../utils/localization_helper.dart';
import 'video_player_screen.dart';

/// Video Materials Screen
/// Flat video list with search and sort controls.
class VideoMaterialsScreen extends StatefulWidget {
  const VideoMaterialsScreen({super.key});

  @override
  State<VideoMaterialsScreen> createState() => _VideoMaterialsScreenState();
}

class _VideoMaterialsScreenState extends State<VideoMaterialsScreen> {
  final VideoRepository _repository = VideoRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<VideoItem>> _videosFuture;

  bool _showSearchBar = false;
  int _sortMode = 0; // 0: display_order, 1: latest, 2: duration desc

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

  void _loadVideos() {
    debugPrint('📺 VideoMaterialsScreen: loading videos');
    _videosFuture = _repository.fetchAllVideos();
  }

  void _retry() {
    debugPrint('🔄 VideoMaterialsScreen: retry tapped');
    setState(_loadVideos);
  }

  List<VideoItem> _applySearchAndSort(List<VideoItem> videos, String langCode) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = videos.where((video) {
      if (query.isEmpty) return true;
      final title = video.getLocalizedTitle(langCode).toLowerCase();
      final altTitleIt = video.titleIt.toLowerCase();
      return title.contains(query) || altTitleIt.contains(query);
    }).toList();

    switch (_sortMode) {
      case 1:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 2:
        filtered.sort((a, b) => (b.durationMinutes ?? 0).compareTo(a.durationMinutes ?? 0));
        break;
      default:
        filtered.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    debugPrint(
      '🔎 VideoMaterialsScreen: query="$query", sortMode=$_sortMode, filtered=${filtered.length}/${videos.length}',
    );
    return filtered;
  }

  String _sortLabel() {
    switch (_sortMode) {
      case 1:
        return 'Latest';
      case 2:
        return 'Longest';
      default:
        return 'Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.videoLibraryTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.search_off : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                }
              });
            },
            tooltip: 'Search',
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.sort, color: theme.colorScheme.onSurface),
            onSelected: (value) => setState(() => _sortMode = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('Default order')),
              PopupMenuItem(value: 1, child: Text('Latest first')),
              PopupMenuItem(value: 2, child: Text('Longest duration')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _retry();
            },
            tooltip: l10n.videoRefresh,
          ),
        ],
      ),
      body: FutureBuilder<List<VideoItem>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('⏳ VideoMaterialsScreen: FutureBuilder waiting');
            return _buildLoadingView();
          }
          if (snapshot.hasError) {
            debugPrint(
              '❌ VideoMaterialsScreen: FutureBuilder error type=${snapshot.error.runtimeType} error=${snapshot.error}',
            );
            return _buildErrorView(snapshot.error);
          }

          final videos = snapshot.data ?? [];
          debugPrint('✅ VideoMaterialsScreen: FutureBuilder data videos=${videos.length}');
          if (videos.isEmpty) {
            return _buildEmptyView();
          }

          final visibleVideos = _applySearchAndSort(videos, languageCode);
          return Column(
            children: [
              if (_showSearchBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search videos',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${visibleVideos.length} ${l10n.videoTitle}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _sortLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleVideos.isEmpty
                    ? _buildNoSearchResults(theme)
                    : RefreshIndicator(
                        onRefresh: () async => _retry(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: visibleVideos.length,
                          itemBuilder: (_, index) => _buildVideoCard(visibleVideos[index], languageCode),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(VideoItem video, String languageCode) {
    final theme = Theme.of(context);
    final title = video.getLocalizedTitle(languageCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnailImageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.video_library, size: 44),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (video.durationMinutes != null) ...[
                        Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${video.durationMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Icon(Icons.sort, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '#${video.displayOrder}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(
            'No matching videos found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.videoLoading,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object? error) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isOffline = error is VideoOfflineException;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? l10n.videoErrorOffline : l10n.videoErrorLoading,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isOffline ? l10n.videoErrorOfflineDesc : l10n.videoErrorLoadingDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _retry();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.videoRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.videoEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
