import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../utils/theme.dart';
import '../../utils/localization_helper.dart';
import '../../models/video_models.dart';

/// Video Player Screen
/// Plays YouTube videos with fullscreen support and video information
class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = widget.video.videoId;
    if (videoId == null) {
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'it',
        forceHD: false,
        loop: false,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_playerListener);
  }

  void _playerListener() {
    if (_isPlayerReady && mounted) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    if (widget.video.videoId != null) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (widget.video.videoId != null) {
      _controller.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final videoTitle = widget.video.getLocalizedTitle(languageCode);

    if (widget.video.videoId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.videoInvalidUrl,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        setState(() => _isFullscreen = true);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        setState(() => _isFullscreen = false);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.colorScheme.primary,
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              videoTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
        builder: (context, player) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            appBar: _isFullscreen
                ? null
                : AppBar(
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
                      l10n.videoPlayerTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.fullscreen,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          _controller.toggleFullScreenMode();
                        },
                      ),
                    ],
                  ),
            body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player
                player,

                // Video Information
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        videoTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Duration
                      if (widget.video.durationMinutes != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.video.durationMinutes} min',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Tips Card
                      _buildInfoCard(theme, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(ThemeData theme, dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.videoTipsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow(
            theme,
            Icons.fullscreen,
            l10n.videoTipFullscreen,
          ),
          const SizedBox(height: 8),
          _buildTipRow(
            theme,
            Icons.speed,
            l10n.videoTipSpeed,
          ),
          const SizedBox(height: 8),
          _buildTipRow(
            theme,
            Icons.closed_caption,
            l10n.videoTipCaptions,
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(ThemeData theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
