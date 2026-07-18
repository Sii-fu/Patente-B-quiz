import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';
import 'admin_video_edit_screen.dart';

/// Which subset of videos the list is currently showing.
enum VideoFilter { all, live, chapter }

/// How the (locally held) video list is ordered.
enum VideoSort { date, chapter }

/// Unified Admin Video Management screen.
///
/// Presents both "Live Classes" and "Chapter-wise Class Videos" from the
/// `videos` table in a single high-density list. Filtering (All / Live only /
/// Chapter only) and sorting (Latest date / Chapter number) are performed
/// entirely in memory against [_allVideos] via [_visibleVideos], so toggling a
/// chip never hits the database — a refetch happens only on explicit refresh or
/// after a create/edit/delete mutation.
class AdminVideoManagementScreen extends StatefulWidget {
  const AdminVideoManagementScreen({super.key});

  @override
  State<AdminVideoManagementScreen> createState() =>
      _AdminVideoManagementScreenState();
}

class _AdminVideoManagementScreenState
    extends State<AdminVideoManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();

  List<Map<String, dynamic>> _allVideos = [];
  bool _isLoading = true;
  String? _error;

  VideoFilter _filter = VideoFilter.all;
  VideoSort _sort = VideoSort.date;

  // Tag palette — blue for live classes, brown for chapter classes.
  static const Color _liveColor = Color(0xFF1565C0);
  static const Color _chapterColor = Color(0xFF6D4C41);

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final videos = await _adminRepository.getVideosWithChapters();
      if (!mounted) return;
      setState(() {
        _allVideos = videos;
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

  // ── Local filter + sort (no DB round-trip) ──────────────────────────────────

  bool _isLive(Map<String, dynamic> video) => video['is_live_class'] == true;

  int? _chapterNumber(Map<String, dynamic> video) {
    // `chapter_number` is the 1-based id-rank computed in the repository; it is
    // the source of truth. Fall back to the chapter's `display_order` only if a
    // number wasn't attached (e.g. a stale/manually-built row).
    final number = _toInt(video['chapter_number']);
    if (number != null) return number;
    final chapter = video['chapter'];
    if (chapter is Map && chapter['display_order'] != null) {
      return _toInt(chapter['display_order']);
    }
    return null;
  }

  List<Map<String, dynamic>> get _visibleVideos {
    final filtered = _allVideos.where((video) {
      switch (_filter) {
        case VideoFilter.all:
          return true;
        case VideoFilter.live:
          return _isLive(video);
        case VideoFilter.chapter:
          return !_isLive(video);
      }
    }).toList();

    if (_sort == VideoSort.chapter) {
      // Chapter number ascending (Lezione 1 → 25); videos without a chapter
      // (e.g. live classes) sink to the bottom rather than throwing.
      filtered.sort((a, b) {
        final na = _chapterNumber(a) ?? 1 << 30;
        final nb = _chapterNumber(b) ?? 1 << 30;
        return na.compareTo(nb);
      });
    } else {
      filtered.sort((a, b) => _dateMillis(b).compareTo(_dateMillis(a)));
    }
    return filtered;
  }

  int _dateMillis(Map<String, dynamic> video) {
    final raw = video['class_date'] ?? video['created_at'];
    if (raw is String) {
      return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    }
    if (raw is DateTime) return raw.millisecondsSinceEpoch;
    return 0;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _getLocalizedTitle(Map<String, dynamic> item, String langCode) {
    switch (langCode) {
      case 'en':
        return (item['title_en'] ?? item['title_it'] ?? '').toString();
      case 'bn':
        return (item['title_bn'] ?? item['title_it'] ?? '').toString();
      default:
        return (item['title_it'] ?? '').toString();
    }
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    return regExp.firstMatch(url)?.group(1);
  }

  String? _getThumbnailUrl(Map<String, dynamic> video) {
    final explicit = (video['thumbnail_url'] ?? '').toString();
    if (explicit.isNotEmpty) return explicit;
    final id = _extractYouTubeId((video['youtube_url'] ?? '').toString());
    return id != null ? 'https://img.youtube.com/vi/$id/mqdefault.jpg' : null;
  }

  String _formatDate(Map<String, dynamic> video) {
    final raw = video['class_date'] ?? video['created_at'];
    DateTime? date;
    if (raw is String) date = DateTime.tryParse(raw);
    if (raw is DateTime) date = raw;
    if (date == null) return '';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  // ── Navigation & mutations ──────────────────────────────────────────────────

  Future<void> _openEditor({
    Map<String, dynamic>? video,
    bool? initialIsLiveClass,
  }) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVideoEditScreen(
          video: video,
          initialIsLiveClass: initialIsLiveClass,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadVideos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminSavedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Bottom-sheet choice dialog asked before every new upload.
  Future<void> _showUploadTypeSheet() async {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.adminUploadTypeQuestion,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _UploadTypeButton(
                  icon: Icons.menu_book,
                  label: l10n.adminUploadRegular,
                  color: _chapterColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEditor(initialIsLiveClass: false);
                  },
                ),
                const SizedBox(height: 12),
                _UploadTypeButton(
                  icon: Icons.live_tv,
                  label: l10n.adminUploadLive,
                  color: _liveColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEditor(initialIsLiveClass: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminDeleteVideo),
        content: Text(l10n.adminDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final thumbnailUrl = (video['thumbnail_url'] ?? '').toString();
    if (thumbnailUrl.contains('/storage/v1/object/public/video-thumbnails/')) {
      final path =
          thumbnailUrl.split('/storage/v1/object/public/video-thumbnails/').last;
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

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final videos = _visibleVideos;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminVideoManagement),
        backgroundColor: theme.colorScheme.surfaceTint,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadTypeSheet,
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAddVideo),
      ),
      body: Column(
        children: [
          _buildFilterBar(l10n, theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${videos.length} ${l10n.adminVideos}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(l10n, theme, videos)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips.
          Wrap(
            spacing: 8,
            children: [
              _filterChip(l10n.adminFilterAll, VideoFilter.all),
              _filterChip(l10n.adminFilterLiveOnly, VideoFilter.live),
              _filterChip(l10n.adminFilterChapterOnly, VideoFilter.chapter),
            ],
          ),
          const SizedBox(height: 4),
          // Sort toggle: date (default) vs chapter number.
          Row(
            children: [
              Icon(Icons.sort, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.adminSortByDate),
                selected: _sort == VideoSort.date,
                onSelected: (_) => setState(() => _sort = VideoSort.date),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.adminSortByChapter),
                selected: _sort == VideoSort.chapter,
                onSelected: (_) => setState(() => _sort = VideoSort.chapter),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VideoFilter value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    ThemeData theme,
    List<Map<String, dynamic>> videos,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVideos, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (videos.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 100),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildVideoRow(l10n, theme, videos[index]),
      ),
    );
  }

  Widget _buildVideoRow(
    AppLocalizations l10n,
    ThemeData theme,
    Map<String, dynamic> video,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    final title = _getLocalizedTitle(video, langCode);
    final thumbnailUrl = _getThumbnailUrl(video);
    final duration = _toInt(video['duration_minutes']);
    final isLive = _isLive(video);
    final chapterNumber = _chapterNumber(video);
    final dateLabel = _formatDate(video);

    return InkWell(
      onTap: () => _openEditor(video: video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading 60x60 thumbnail.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnailFallback(theme),
                      )
                    : _thumbnailFallback(theme),
              ),
            ),
            const SizedBox(width: 12),
            // Title + metadata chips.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isLive)
                        _tag(l10n.adminTagLive, _liveColor)
                      else
                        _tag(
                          l10n.adminTagChapter(chapterNumber ?? 0),
                          _chapterColor,
                        ),
                      if (dateLabel.isNotEmpty)
                        _metaChip(Icons.calendar_today, dateLabel, theme),
                      if (duration != null)
                        _metaChip(Icons.schedule, '${duration}m', theme),
                    ],
                  ),
                ],
              ),
            ),
            // Trailing actions.
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit, size: 20),
              tooltip: l10n.adminEdit,
              onPressed: () => _openEditor(video: video),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              tooltip: l10n.adminDelete,
              onPressed: () => _deleteVideo(video),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailFallback(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.play_circle_outline, color: Colors.grey),
      );

  /// Solid coloured category tag (LIVE / CHAPTER X).
  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Muted metadata chip (date / duration).
  Widget _metaChip(IconData icon, String label, ThemeData theme) {
    final color = theme.colorScheme.onSurface.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

/// Large, distinct action button used inside the upload-type bottom sheet.
class _UploadTypeButton extends StatelessWidget {
  const _UploadTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
