import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/video_models.dart';
import '../../repositories/video_repository.dart';
import '../../utils/localization_helper.dart';
import '../../utils/theme.dart';
import 'video_player_screen.dart';

/// Chapter Videos screen
/// Displays the (non-live) videos belonging to a single theory chapter as a
/// vertical list of thumbnail cards. Tapping a video opens the player.
class ChapterVideosScreen extends StatefulWidget {
  final int chapterId;
  final String? chapterTitle;

  const ChapterVideosScreen({
    super.key,
    required this.chapterId,
    this.chapterTitle,
  });

  @override
  State<ChapterVideosScreen> createState() => _ChapterVideosScreenState();
}

class _ChapterVideosScreenState extends State<ChapterVideosScreen> {
  final VideoRepository _repository = VideoRepository();
  late Future<List<VideoItem>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    _videosFuture = _repository.fetchVideosByChapter(widget.chapterId);
  }

  void _retry() {
    setState(_loadVideos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.chapterTitle ?? l10n.videoTitle,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _retry();
                      },
                      tooltip: l10n.videoRefresh,
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildBody(languageCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String languageCode) {
    return FutureBuilder<List<VideoItem>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingView();
          }

          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          }

          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return _buildEmptyView();
          }

          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: () async => _retry(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: videos.length,
              itemBuilder: (_, index) {
                final item = videos[index];
                final title = item.getLocalizedTitle(languageCode);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: item)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 130,
                              height: 78,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: item.thumbnailImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.video_library, size: 30),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.formattedDuration != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.formattedDuration!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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
